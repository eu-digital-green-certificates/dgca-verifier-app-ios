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
//  UIFont.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/28/21.
//
//  https://stackoverflow.com/a/53818276/2585092
//

import UIKit

extension UIFont {
  public var weight: UIFont.Weight {
    guard let weightNumber = traits[.weight] as? NSNumber else { return .regular }
    let weightRawValue = CGFloat(weightNumber.doubleValue)
    let weight = UIFont.Weight(rawValue: weightRawValue)
    return weight
  }

  private var traits: [UIFontDescriptor.TraitKey: Any] {
    return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
  }
}
