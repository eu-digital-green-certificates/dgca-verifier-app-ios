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

protocol DataStorageProtocol {
  associatedtype StorageData: Codable
  associatedtype DataModel: Codable
  var storageData: StorageData {get set}
  var storage: SecureStorage<StorageData> {get set}
  func save()
  func initialize(completion: @escaping () -> Void)
  func add(dataModel:DataModel)
}

class DataCenter {
  static let shared = DataCenter()
  
  static let localDataManager: LocalDataManager = LocalDataManager()
  static let countryDataManager: CountryDataManager = CountryDataManager()
  static let rulesDataManager: RulesDataManager = RulesDataManager()
  static let valueSetsDataManager: ValueSetsDataManager = ValueSetsDataManager()
  
  static var lastFetch: Date {
    get {
      let fetchDate = localDataManager.localData.lastFetch
      return fetchDate
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
      return countryDataManager.countryData.countryCodes
    }
    set {
      countryDataManager.countryData.countryCodes = newValue
     }
  }
  
  static var rules: [CertLogic.Rule] {
    get {
      return rulesDataManager.rulesData.rules
    }
    set {
      rulesDataManager.rulesData.rules = newValue
     }
  }
  
  static var valueSets: [CertLogic.ValueSet] {
    get {
      return valueSetsDataManager.valueSetsData.valueSets
    }
    set {
      valueSetsDataManager.valueSetsData.valueSets = newValue
     }
  }

  static func saveLocalData() {
    localDataManager.localData.lastFetch = Date()
    localDataManager.save()
  }
  
  static func saveCountries() {
    countryDataManager.countryData.lastFetch = Date()
    countryDataManager.save()
  }
  
  static func saveSets() {
    valueSetsDataManager.valueSetsData.lastFetch = Date()
    valueSetsDataManager.save()
  }

  static func saveRules() {
    rulesDataManager.rulesData.lastFetch = Date()
    rulesDataManager.save()
  }
  
  static func initializeStorageData(completion: @escaping () -> Void) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.initialize {
      
      group.enter()
      rulesDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      countryDataManager.initialize {
        group.leave()
      }
      
      group.leave()
    }
    group.notify(queue: .main) {
      completion()
    }
  }

  static func reloadStorageData(completion: @escaping () -> Void) {
    let group = DispatchGroup()
    
    group.enter()
    localDataManager.initialize {
      
      group.enter()
      rulesDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      valueSetsDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      countryDataManager.initialize {
        group.leave()
      }
      
      group.enter()
      GatewayConnection.updateLocalDataStorage {
        group.leave()
      }

      group.enter()
      GatewayConnection.loadCountryList { _ in
        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadValueSetsFromServer { _ in
        group.leave()
      }
      
      group.enter()
      GatewayConnection.loadRulesFromServer { _ in
        CertLogicEngineManager.sharedInstance.setRules(ruleList: rulesDataManager.rulesData.rules)
        group.leave()
      }

      group.leave()
    }
    group.notify(queue: .main) {
      lastFetch = Date()
      completion()
    }
  }
}
