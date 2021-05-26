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

struct Certificates {
  static let certificate = Certificates.certificate(filename: "testaka4-sogei-it")
  
  private static func certificate(filename: String) -> SecCertificate {
    let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
    let certificate = SecCertificateCreateWithData(nil, data as CFData)!
    
    return certificate
  }
}

class GatewayConnection {
    //  static let serverURI = "https://dgca-verifier-service.cfapps.eu10.hana.ondemand.com/"
    //  static let updateEndpoint = "signercertificateUpdate"
    //  static let statusEndpoint = "signercertificateStatus"
    
    private let serverURI = "https://testaka4.sogei.it/v1/dgc/"
    private let updateEndpoint = "signercertificate/update"
    private let statusEndpoint = "signercertificate/status"
    private let settingsEndpoint = "settings"
    
    private let evaluators = ["testaka4.sogei.it": PinnedCertificatesTrustEvaluator(certificates: [Certificates.certificate])]
    private let session: Session
    private var timer: Timer?
    
    init() {
        session = Session(serverTrustManager: ServerTrustManager(evaluators: evaluators))
    }
    
    func start(completion: ((String?, Bool?) -> Void)?) {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.trigger()
        }
        timer?.tolerance = 5.0
        update(completion: completion)
        settings()
    }
    
    func certUpdate(resume resumeToken: String? = nil, completion: ((String?, String?, String?) -> Void)?) {
        var headers = [String: String]()
        if let token = resumeToken {
            headers["x-resume-token"] = token
        }
        session.request(
            serverURI + updateEndpoint,
            method: .get,
            parameters: nil,
            encoding: URLEncoding(),
            headers: .init(headers),
            interceptor: nil,
            requestModifier: nil
        ).response {
            if let status = $0.response?.statusCode, status == 204 {
                completion?(nil, nil, "No content from server.")
                return
            }
            
            if let status = $0.response?.statusCode, status == 403 {
                completion?(nil, nil, "server.error.noAuthorization".localized)
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
        AF.request(serverURI + statusEndpoint).response {
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
        AF.request(serverURI + settingsEndpoint).response {
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
            LocalData.sharedInstance.save()
            
            self?.settings(completion: completion)
        }
    }
    
    private func settings(completion: ((String?, Bool?) -> Void)? = nil) {
        getSettings { settings in
            for setting in settings {
                LocalData.sharedInstance.addOrUpdateSettings(setting)
            }
            
            // Check min version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let minVersion = settings.first(where: { $0.name == "ios" && $0.type == "APP_MIN_VERSION" })?.value {
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
