//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  GatewayConnection.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/24/21.
//  

import Foundation
import Alamofire
import SwiftDGC
import SwiftyJSON

extension Bundle {
    func infoForKey(_ key: String) -> String? {
        return (Bundle.main.infoDictionary?[key] as? String)?.replacingOccurrences(of: "\\", with: "")
    }
}

class GatewayConnection {
    //  static let serverURI = "https://dgca-verifier-service.cfapps.eu10.hana.ondemand.com/"
    //  static let updateEndpoint = "signercertificateUpdate"
    //  static let statusEndpoint = "signercertificateStatus"
    
    private let baseUrl: String
    private let updateEndpoint: String
    private let statusEndpoint: String
    private let settingsEndpoint: String
    private let certificateFilename: String
    private let certificateEvaluator: String
    
    private let session: Session
    private var timer: Timer?
    
    init() {
        // Init config
        baseUrl = Bundle.main.infoForKey("baseUrl")!
        updateEndpoint = Bundle.main.infoForKey("updateEndpoint")!
        statusEndpoint = Bundle.main.infoForKey("statusEndpoint")!
        settingsEndpoint = Bundle.main.infoForKey("settingsEndpoint")!
        certificateFilename = Bundle.main.infoForKey("certificateFilename")!
        certificateEvaluator = Bundle.main.infoForKey("certificateEvaluator")!
        
        // Init certificate for pinning
        let filePath = Bundle.main.path(forResource: certificateFilename, ofType: nil)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!
                    
        // Init session
        let evaluators = [certificateEvaluator: PinnedCertificatesTrustEvaluator(certificates: [certificate])]
        session = Session(serverTrustManager: ServerTrustManager(evaluators: evaluators))
    }
        
    func start(completion: ((String?, Bool?) -> Void)?) {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.trigger()
        }
        timer?.tolerance = 5.0
        update(completion: completion)
    }
    
    func certUpdate(resume resumeToken: String? = nil, completion: ((String?, String?, String?) -> Void)?) {
        var headers = [String: String]()
        if let token = resumeToken {
            headers["x-resume-token"] = token
        }
        session.request(baseUrl + updateEndpoint,
                        method: .get,
                        parameters: nil,
                        encoding: URLEncoding(),
                        headers: .init(headers),
                        interceptor: nil,
                        requestModifier: nil)
            .response {
                guard let status = $0.response?.statusCode else {
                    completion?(nil, nil, "server.error.genericError".localized)
                    return
                }
                
                // Everything ok, all certificates downloaded, no more content
                if status == 204 {
                    completion?(nil, nil, nil)
                    return
                }
                
                if status > 204 {
                    completion?(nil, nil, "server.error.errorWithStatus".localized + "\(status)")
                    return
                }
                
                guard
                    case let .success(result) = $0.result,
                    let response = result,
                    let responseStr = String(data: response, encoding: .utf8),
                    let headers = $0.response?.headers,
                    let responseKid = headers["x-kid"],
                    let newResumeToken = headers["x-resume-token"]
                else {
                    return
                }
                let kid = KID.from(responseStr)
                let kidStr = KID.string(from: kid)
                if kidStr != responseKid {
                    return
                }
                completion?(responseStr, newResumeToken, nil)
            }
    }
    
    func certStatus(resume resumeToken: String? = nil, completion: (([String]) -> Void)?) {
        AF.request(baseUrl + statusEndpoint).response {
            guard
                case let .success(result) = $0.result,
                let response = result,
                let responseStr = String(data: response, encoding: .utf8),
                let json = JSON(parseJSON: responseStr).array
            else {
                return
            }
            let kids = json.compactMap { $0.string }
            if kids.isEmpty {
                LocalData.sharedInstance.resumeToken = nil
            }
            completion?(kids)
        }
    }
    
    func getSettings(completion: (([Setting]) -> Void)?) {
        AF.request(baseUrl + settingsEndpoint).response {
            guard let data = $0.data else { return }
            do {
                let decoder = JSONDecoder()
                let settingsWrapper = try decoder.decode([Setting].self, from: data)
                completion?(settingsWrapper)
            } catch let error {
                print(error)
            }
        }
    }
    
    private func trigger(completion: ((String?, Bool?) -> Void)? = nil) {
        guard LocalData.sharedInstance.lastFetch.timeIntervalSinceNow < -24 * 60 * 60 else {
            completion?(nil, nil)
            return
        }
        update(completion: completion)
    }
    
    private func update(completion: ((String?, Bool?) -> Void)? = nil) {
        certUpdate(resume: LocalData.sharedInstance.resumeToken) { [weak self] encodedCert, token, error in
            
            if error != nil {
                completion?(error, nil)
                return
            }
            
            guard let encodedCert = encodedCert else {
                self?.status(completion: completion)
                return
            }
            LocalData.sharedInstance.add(encodedPublicKey: encodedCert)
            LocalData.sharedInstance.resumeToken = token
            self?.update(completion: completion)
        }
    }
    
    private func status(completion: ((String?, Bool?) -> Void)? = nil) {
        certStatus {  [weak self] validKids in
            let invalid = LocalData.sharedInstance.encodedPublicKeys.keys.filter {
                !validKids.contains($0)
            }
            for key in invalid {
                LocalData.sharedInstance.encodedPublicKeys.removeValue(forKey: key)
            }
            LocalData.sharedInstance.lastFetch = Date()
            
            self?.settings(completion: completion)
        }
    }
    
    private func settings(completion: ((String?, Bool?) -> Void)? = nil) {
        getSettings { settings in
            for setting in settings {
                LocalData.sharedInstance.addOrUpdateSettings(setting)
            }
            LocalData.sharedInstance.save()
            
            // Check min version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let minVersion = LocalData.sharedInstance.settings.first(where: { $0.name == "ios" && $0.type == "APP_MIN_VERSION" })?.value {
                if version.compare(minVersion, options: .numeric) == .orderedAscending {
                    completion?(nil, true)
                }
                else {
                    completion?(nil, false)
                }
            }
        }
    }
}
