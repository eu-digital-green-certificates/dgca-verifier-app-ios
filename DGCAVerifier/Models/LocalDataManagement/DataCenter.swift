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
//  DataCenter.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 03.11.2021.
//  
        

import Foundation
import SwiftDGC
import CertLogic

class DataCenter {
    static let shared = DataCenter()
    static var appVersion: String {
        let versionValue = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"
        let buildNumValue = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?.?.?"
        return "\(versionValue)(\(buildNumValue))"
    }
    static let localDataManager: LocalDataManager = LocalDataManager()
    static let revocationWorker: RevocationWorker = RevocationWorker()
    
    static var downloadedDataHasExpired: Bool {
        return lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
    }
   
    static var appWasRunWithOlderVersion: Bool {
        return localDataManager.localData.lastLaunchedAppVersion != appVersion
    }

    static var lastFetch: Date {
        get {
            return localDataManager.localData.lastFetch
        }
        set {
            localDataManager.localData.lastFetch = newValue
        }
    }
    
    static var resumeToken: String? {
        get {
            return localDataManager.localData.resumeToken
        }
        set {
            localDataManager.localData.resumeToken = newValue
        }
    }
    
    static var publicKeys: [String: [String]] {
        get {
            return localDataManager.localData.encodedPublicKeys
        }
        set {
            localDataManager.localData.encodedPublicKeys = newValue
        }
    }

    static var countryCodes: [CountryModel] {
        get {
            return localDataManager.localData.countryCodes
        }
        set {
            localDataManager.localData.countryCodes = newValue
        }
    }

    static var rules: [Rule] {
        get {
          return localDataManager.localData.rules
        }
        set {
            localDataManager.localData.rules = newValue
        }
    }
    
    static var valueSets: [ValueSet] {
        get {
          return localDataManager.localData.valueSets
        }
        set {
            localDataManager.localData.valueSets = newValue
        }
    }

    static func saveLocalData(completion: @escaping DataCompletionHandler) {
        localDataManager.save(completion: completion)
    }
    
    class func prepareLocalData(completion: @escaping DataCompletionHandler) {
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            let shouldDownload = self.downloadedDataHasExpired || self.appWasRunWithOlderVersion
            if !shouldDownload {
                completion(result)
            } else {
                reloadStorageData { result in
                    localDataManager.loadLocallyStoredData(completion: completion)
                }
            }
        }
    }
    
    static func reloadStorageData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
        
        let center = NotificationCenter.default
        center.post(name: Notification.Name("StartLoadingNotificationName"), object: nil, userInfo: nil )
        
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            
            group.enter()
            GatewayConnection.updateLocalDataStorage { group.leave() }
            
            group.enter()
            GatewayConnection.loadCountryList { _ in group.leave()  }
            
            group.enter()
            GatewayConnection.loadValueSetsFromServer { _, err in group.leave() }
            
            group.enter()
            GatewayConnection.loadRulesFromServer { _, err  in
              CertLogicManager.shared.setRules(ruleList: rules)
              group.leave()
            }
            
            group.leave()
        }
        
        group.enter()
        try? revocationWorker.processReloadRevocations { err in
             group.leave()
        }

        group.notify(queue: .main) {
            localDataManager.localData.lastFetch = Date()
            center.post(name: Notification.Name("StopLoadingNotificationName"), object: nil, userInfo: nil )
            completion(.success(true))
        }
    }
}
