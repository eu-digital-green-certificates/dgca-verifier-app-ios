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
//  ValidityState.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 02.11.2021.
//  
        

import UIKit
import SwiftDGC

extension ValidityState {
    
    var technicalValidityString: String {
        switch self.technicalValidity {
          case .valid:
            return Icons.ok.rawValue
          case .invalid:
            return Icons.error.rawValue
          case .ruleInvalid:
            return Icons.limited.rawValue
        }
    }

    var issuerInvalidationString: String {
        switch self.issuerInvalidation {
          case .passed:
            return Icons.ok.rawValue
          case .error:
            return Icons.error.rawValue
          case .open:
            return Icons.limited.rawValue
        }
    }

    var destinationAcceptenceString: String {
        switch self.destinationAcceptence {
        case .passed:
          return Icons.ok.rawValue
        case .error:
          return Icons.error.rawValue
        case .open:
          return Icons.limited.rawValue
        }
    }
    
    var travalerAcceptenceString: String {
        switch self.travalerAcceptence {
        case .passed:
          return Icons.ok.rawValue
        case .error:
          return Icons.error.rawValue
        case .open:
          return Icons.limited.rawValue
        }
    }
    
    var technicalValidityColor: UIColor {
        switch self.technicalValidity {
          case .valid:
            return UIColor.certificateValid
          case .invalid:
            return UIColor.certificateInvalid
          case .ruleInvalid:
            return UIColor.certificateRuleOpen
        }
    }

    var issuerInvalidationColor: UIColor {
        switch self.issuerInvalidation {
          case .passed:
            return UIColor.certificateValid
          case .error:
            return UIColor.certificateInvalid
          case .open:
            return UIColor.certificateRuleOpen
        }
    }

    var destinationAcceptenceColor: UIColor {
        switch self.destinationAcceptence {
        case .passed:
          return UIColor.certificateValid
        case .error:
          return UIColor.certificateInvalid
        case .open:
          return UIColor.certificateRuleOpen
        }
    }
    
    var travalerAcceptenceColor: UIColor {
    switch self.travalerAcceptence {
    case .passed:
      return UIColor.certificateValid
    case .error:
        return UIColor.certificateInvalid
    case .open:
        return UIColor.certificateRuleOpen
    }
  }
}
