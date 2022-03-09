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
//  UIColor+Verifier.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/29/21.
//  

import UIKit

extension UIColor {
  static var certificateRed: UIColor { UIColor(named: "certificateRed")! }
  static var certificateGreen: UIColor { UIColor(named: "certificateGreen")! }
  static var verifierBlue: UIColor { UIColor(named: "verifierBlue")! }
  static var charcoalGrey: UIColor { UIColor(named: "charcoalGrey")! }
  static var certificateLimited: UIColor { UIColor(named: "certificateLimited")! }
  static var certificateValid: UIColor { UIColor(named: "certificateValid")! }
  static var certificateInvalid: UIColor! { UIColor(named: "certificateInvalid")! }
  static var certificateRuleOpen: UIColor { UIColor(named: "certificateRuleOpen")! }
}
