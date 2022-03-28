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
//  LocalDataManager.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

class LocalDataManager {
    lazy var storage = SecureStorage<LocalData>(fileName: SharedConstants.dataStorageName)
    var localData = LocalData()
    
    // MARK: - Public Keys
    func add(encodedPublicKey: String) {
        let kid = KID.from(encodedPublicKey)
        let kidStr = KID.string(from: kid)
        
        let list = localData.encodedPublicKeys[kidStr] ?? []
        if !list.contains(encodedPublicKey) {
          localData.encodedPublicKeys[kidStr] = list + [encodedPublicKey]
        }
    }
    
    // MARK: - Countries
    func add(country: CountryModel) {
        if !localData.countryCodes.contains(where: { $0.code == country.code }) {
            localData.countryCodes.append(country)
        }
    }
    
    func update(country: CountryModel) {
        guard let countryFromDB = localData.countryCodes.filter({ $0.code == country.code }).first else { return }
        countryFromDB.debugModeEnabled = country.debugModeEnabled
    }
    
    // MARK: - ValueSets
    func add(valueSet: ValueSet) {
        if !localData.valueSets.contains(where: { $0.valueSetId == valueSet.valueSetId }) {
          localData.valueSets.append(valueSet)
        }
    }
    
    func deleteValueSetWithHash(hash: String) {
        localData.valueSets = localData.valueSets.filter { $0.hash != hash }
    }
    
    func isValueSetExistWithHash(hash: String) -> Bool {
        return localData.valueSets.contains(where: { $0.hash == hash })
    }
    
    public func getValueSetsForExternalParameters() -> Dictionary<String, [String]> {
        var returnValue = Dictionary<String, [String]>()
        localData.valueSets.forEach { valueSet in
            let keys = Array(valueSet.valueSetValues.keys)
            returnValue[valueSet.valueSetId] = keys
        }
        return returnValue
    }

    // MARK: - Rules
    func add(rule: Rule) {
        if !localData.rules.contains(where: { $0.identifier == rule.identifier && $0.version == rule.version }) {
          localData.rules.append(rule)
      }
    }
    
    func deleteRuleWithHash(hash: String) {
        localData.rules = localData.rules.filter { $0.hash != hash }
    }
      
    func isRuleExistWithHash(hash: String) -> Bool {
        return localData.rules.contains(where: { $0.hash == hash })
    }

    // MARK: - Config
    func merge(other: JSON) {
      localData.config.merge(other: other)
    }
    
    var versionedConfig: JSON {
        if localData.config["versions"][DataCenter.appVersion].exists() {
          return localData.config["versions"][DataCenter.appVersion]
        } else {
          return localData.config["versions"]["default"]
        }
    }

    // MARK: - Services
    func save(completion: @escaping DataCompletionHandler) {
        storage.save(localData, completion: completion)
    }

    func loadLocallyStoredData(completion: @escaping DataCompletionHandler) {
        storage.loadStoredData(fallback: localData) { [unowned self] data in
            guard let loadedData = data else {
              completion(.failure(DataOperationError.noInputData))
              return
            }
            DGCLogger.logInfo(String(format: "%d pub keys loaded.", loadedData.encodedPublicKeys.count))
            if loadedData.lastLaunchedAppVersion != DataCenter.appVersion {
              loadedData.config = self.localData.config
              loadedData.lastLaunchedAppVersion = DataCenter.appVersion
            }
            self.localData = loadedData
            self.save(completion: completion)
            CoreManager.publicKeyEncoder = LocalDataKeyEncoder()
        }
    }
}

class LocalDataKeyEncoder: PublicKeyStorageDelegate {
    func getEncodedPublicKeys(for kidStr: String) -> [String] {
        DataCenter.localDataManager.localData.encodedPublicKeys[kidStr] ?? []
    }
}
