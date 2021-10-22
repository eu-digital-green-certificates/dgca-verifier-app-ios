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
//  DebugManager.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 06.09.2021.
//  

let debugKey = "UDDebugSwitchConstants"
let logLevelKey = "UDLogLevelConstants"

import UIKit
import SwiftDGC

enum DebugLevel: Int {
  case level1 = 0
  case level2
  case level3
}

class DebugManager: NSObject {
  static var sharedInstance: DebugManager = {
    let instance = DebugManager()
    return instance
  }()
  
  var isDebugMode: Bool {
    set {
      UserDefaults.standard.set(newValue, forKey: debugKey)
    }
    get {
      return UserDefaults.standard.bool(forKey: debugKey)
    }
  }
  
  var debugLevel: DebugLevel {
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: logLevelKey)
    }
    get {
      let logLevel = UserDefaults.standard.integer(forKey: logLevelKey)
      return DebugLevel.init(rawValue: logLevel) ?? .level1
    }
  }
  
  func isDebugModeFor(country: String, hCert: HCert?) -> Bool {
    guard isDebugMode, let hCert = hCert else { return false }
    
    let validator = CertificateValidator(with: hCert)
    let validationResult = validator.validate()
    if validationResult.technicalValidity != .valid ||
        validationResult.issuerInvalidation != .passed ||
        validationResult.destinationAcceptence != .passed ||
        validationResult.travalerAcceptence != .passed {
      let codes = CountryDataStorage.sharedInstance.countryCodes
      guard let countryModel = codes.filter({ $0.code == country }).first else { return false }
      if countryModel.debugModeEnabled {
        return true
      }
    }
    return false
  }
}
