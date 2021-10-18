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
//  CertificateValidity.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 18.10.2021.
//  
        

import Foundation
import SwiftyJSON
import SwiftDGC
import CertLogic

struct CertificateValidity {
    static var invalid = CertificateValidity(technicalValidity: .invalid,
        issuerValidity: .invalid,
        destinationValidity: .invalid,
        travalerValidity: .invalid,
        allRulesValidity: .invalid,
        validityFailures: [],
        infoRulesSection: nil)
    
    let technicalValidity: HCertValidity
    let issuerValidity: HCertValidity
    let destinationValidity: HCertValidity
    let travalerValidity: HCertValidity
    let allRulesValidity: HCertValidity
    let validityFailures: [String]
    var infoRulesSection: InfoSection?
    
    private var validity: HCertValidity {
      return validityFailures.isEmpty ? .valid : .invalid
    }
    
    var isValid: Bool {
      return validityFailures.isEmpty
    }

    var issuerInvalidation: RuleValidationResult {
        let ruleResult: RuleValidationResult
        switch issuerValidity {
          case .valid:
            ruleResult = .passed
          case .invalid:
            ruleResult = .error
          case .ruleInvalid:
            ruleResult = .open
        }
        return ruleResult
    }
    
    var destinationAcceptence: RuleValidationResult {
        let ruleResult: RuleValidationResult
        switch destinationValidity {
          case .valid:
            ruleResult = .passed
          case .invalid:
            ruleResult = .error
          case .ruleInvalid:
            ruleResult = .open
        }
        return ruleResult
    }
    
    var travalerAcceptence: RuleValidationResult {
        let ruleResult: RuleValidationResult
        switch travalerValidity {
          case .valid:
            ruleResult = .passed
          case .invalid:
            ruleResult = .error
          case .ruleInvalid:
            ruleResult = .open
        }
        return ruleResult
    }
}
