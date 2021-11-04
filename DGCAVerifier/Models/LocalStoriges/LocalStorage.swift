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
//  LocalStorage.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 03.11.2021.
//  
        

import UIKit
import SwiftDGC
import CertLogic

class LocalStorage {
  static let shared = LocalStorage()
  
  static let dataKeeper: LocalDataKeeper = LocalDataKeeper()
  static let countryKeeper: CountryDataKeeper = CountryDataKeeper()
  static let rulesKeeper: RulesDataKeeper = RulesDataKeeper()
  static let valueSetsKeeper: ValueSetsDataKeeper = ValueSetsDataKeeper()
    
  static var countryCodes: [CountryModel] {
    get {
      return countryKeeper.countryData.countryCodes
    }
    set {
      countryKeeper.countryData.countryCodes = newValue
     }
  }
  
  static var rules: [CertLogic.Rule] {
    get {
      return rulesKeeper.rulesData.rules
    }
    set {
      rulesKeeper.rulesData.rules = newValue
     }
  }

  static func saveCountries() {
    countryKeeper.countryData.lastFetch = Date()
    countryKeeper.save()
  }
  
  static func saveSets() {
    valueSetsKeeper.valueSetsData.lastFetch = Date()
    valueSetsKeeper.save()
  }

  static func saveRules() {
    rulesKeeper.rulesData.lastFetch = Date()
    rulesKeeper.save()
  }
  
  static func initializeStorages(completion: @escaping () -> Void) {
    
    let group = DispatchGroup()
    group.enter()
    rulesKeeper.initialize {
      group.leave()
    }
    
    group.enter()
    valueSetsKeeper.initialize {
      group.leave()
    }
    
    group.enter()
    dataKeeper.initialize {
      group.leave()
    }
    
    group.enter()
    countryKeeper.initialize {
      group.leave()
    }
    
    group.notify(queue: .main) {
      completion()
    }
  }
}
