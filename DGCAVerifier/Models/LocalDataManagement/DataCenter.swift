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
    
    static var resumeToken: String {
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
    
    static func addValueSets(_ list: [ValueSet]) {
        list.forEach { localDataManager.add(valueSet: $0) }
    }
    
    static func addRules(_ list: [Rule]) {
        list.forEach { localDataManager.add(rule: $0) }
    }
    
    static func addCountries(_ list: [CountryModel]) {
        localDataManager.localData.countryCodes.removeAll()
        list.forEach { localDataManager.add(country: $0) }
    }
    
    static func prepareLocalData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            group.leave()
        }
        group.wait()
        
        let areNotDownloadedData = countryCodes.isEmpty || rules.isEmpty || valueSets.isEmpty
        let shouldReloadData = self.downloadedDataHasExpired || self.appWasRunWithOlderVersion
        
        if areNotDownloadedData || shouldReloadData {
            reloadAllStorageData { result in
                if case .failure(_) = result {
                    if areNotDownloadedData {
                        completion(.noData)
                    } else {
                        completion(result)
                    }
                } else {
                    localDataManager.loadLocallyStoredData { result in
                        let areNotDownloadedData = countryCodes.isEmpty || rules.isEmpty || valueSets.isEmpty
                        if areNotDownloadedData {
                            completion(.noData)
                        }
                        CertLogicManager.shared.setRules(ruleList: rules)
                        completion(.success)
                    }
                }
            }
            
        } else {
            localDataManager.loadLocallyStoredData { result in
                CertLogicManager.shared.setRules(ruleList: rules)
                completion(result)
            }
        }
    }
    
    static func reloadAllStorageData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
                
        var errorOccured = false
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            
            group.enter()
            GatewayConnection.updateLocalDataStorage { err in
                if err != nil { errorOccured = true }
                group.leave()
            }
            
            group.enter()
            GatewayConnection.loadCountryList { list, err in
                if err != nil { errorOccured = true }
                group.leave()
            }
            
            group.enter()
            GatewayConnection.loadValueSetsFromServer { list, err in
                if err != nil { errorOccured = true }
                group.leave()
             }
            
            group.enter()
            GatewayConnection.loadRulesFromServer { list, err  in
                if err != nil { errorOccured = true }
                group.leave()
                CertLogicManager.shared.setRules(ruleList: rules)
            }
            group.leave()
        }
        
        group.enter()
        revocationWorker.processReloadRevocations { error in
            if let err = error {
                if case let .failedValidation(status: status) = err, status == 404 {
                    group.enter()
                    revocationWorker.processReloadRevocations { err in
                        if err != nil { errorOccured = true }
                        group.leave()
                    }
                }
                errorOccured = true
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            localDataManager.localData.lastFetch = Date()
            
            if errorOccured == true {
                DispatchQueue.main.async {
                    completion(.failure(.noInputData))
                }
            } else {
                DataCenter.saveLocalData(completion: completion)
            }
        }
    }
}
