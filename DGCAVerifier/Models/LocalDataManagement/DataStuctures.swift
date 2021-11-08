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
//  DataStuctures.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 11/3/21.
//  
        

import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

class LocalData: Codable {
  var encodedPublicKeys = [String: [String]]()
  var resumeToken: String?
  var lastFetchRaw: Date?
  var lastFetch: Date {
    get {
      lastFetchRaw ?? Date.distantPast
    }
    set {
      lastFetchRaw = newValue
    }
  }
  var config = Config.load()
  var lastLaunchedAppVersion = "0.0"
}

class CountryDataStorage: Codable {
  var countryCodes = [CountryModel]()
}

class RulesDataStorage: Codable {
  var rules = [CertLogic.Rule]()
}

class ValueSetsDataStorage: Codable {
  var valueSets = [CertLogic.ValueSet]()
}
