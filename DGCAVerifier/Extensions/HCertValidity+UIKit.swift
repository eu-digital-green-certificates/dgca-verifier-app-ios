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
//  HCertValidity.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 29.10.2021.
//  
        

import UIKit
import SwiftDGC

extension HCertValidity {
  var validityResult: String {
      switch self {
      case .valid:
          return l10n("enum.HCertValidity.valid")
      case .invalid:
          return l10n("enum.HCertValidity.invalid")
      case .ruleInvalid:
          return l10n("um.HCertValidity.ruleInvalid")
      }
    }
    
    var validityImage: UIImage {
      switch self {
      case .valid:
          return UIImage(named: "check")!
      case .invalid:
          return UIImage(named: "error")!
      case .ruleInvalid:
          return UIImage(named: "check")!
      }
    }
    
    var validityButtonTitle: String {
      switch self {
      case .valid:
          return l10n("btn.done")
      case .invalid:
          return l10n("btn.retry")
      case .ruleInvalid:
          return l10n("btn.retry")
      }
    }

    var validityBackground: UIColor {
      switch self {
      case .valid:
          return UIColor.forestGreen
      case .invalid:
          return UIColor.roseRed
      case .ruleInvalid:
          return UIColor.walletYellow
      }
    }
}
