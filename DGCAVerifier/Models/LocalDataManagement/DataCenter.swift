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

import UIKit
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
    static let countryDataManager: CountryDataManager = CountryDataManager()
    static let rulesDataManager: RulesDataManager = RulesDataManager()
    static let valueSetsDataManager: ValueSetsDataManager = ValueSetsDataManager()

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
        return countryDataManager.localData.countryCodes
      }
      set {
        countryDataManager.localData.countryCodes = newValue
      }
    }

    static var rules: [Rule] {
      get {
        return rulesDataManager.localData.rules
      }
      set {
        rulesDataManager.localData.rules = newValue
      }
    }
    
    static var valueSets: [ValueSet] {
      get {
        return valueSetsDataManager.localData.valueSets
      }
      set {
        valueSetsDataManager.localData.valueSets = newValue
      }
    }

    static func saveLocalData(completion: @escaping DataCompletionHandler) {
      localDataManager.save(completion: completion)
    }
    
    static func saveCountries(completion: @escaping DataCompletionHandler) {
      countryDataManager.save(completion: completion)
    }
    
    static func saveSets(completion: @escaping DataCompletionHandler) {
      valueSetsDataManager.save(completion: completion)
    }

    static func saveRules(completion: @escaping DataCompletionHandler) {
      rulesDataManager.save(completion: completion)
    }
    
    
    static func prepareLocalData(completion: @escaping DataCompletionHandler) {
        initializeAllStorageData { localResult in
            let shouldDownload = self.downloadedDataHasExpired || self.appWasRunWithOlderVersion
            if !shouldDownload {
                completion(localResult)
            } else {
                reloadStorageData { result in
                    completion(result)
                }
            }
        }
    }

    static func initializeAllStorageData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
        
        group.enter()
        localDataManager.loadLocallyStoredData { rezult in
            
          group.enter()
          rulesDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            group.leave()
          }
          
          group.enter()
          valueSetsDataManager.loadLocallyStoredData { _ in group.leave() }
          
          group.enter()
          countryDataManager.loadLocallyStoredData { _ in group.leave() }
            
          group.leave()
        }
      
        group.notify(queue: .main) {
          completion(.success(true))
        }
    }

    static func reloadStorageData(completion: @escaping DataCompletionHandler) {
        let group = DispatchGroup()
        
        group.enter()
        localDataManager.loadLocallyStoredData { result in
            
          group.enter()
          rulesDataManager.loadLocallyStoredData { result in
            CertLogicManager.shared.setRules(ruleList: rules)
            group.leave()
          }

          group.enter()
          valueSetsDataManager.loadLocallyStoredData { _ in group.leave() }

          group.enter()
          countryDataManager.loadLocallyStoredData { _ in group.leave() }

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
      
      group.notify(queue: .main) {
          localDataManager.localData.lastFetch = Date()
          completion(.success(true))
      }
    }
}
