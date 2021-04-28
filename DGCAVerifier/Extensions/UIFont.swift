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
//  https://stackoverflow.com/a/48688917/2585092
//

import UIKit


extension UIFont {
  var weight: UIFont.Weight {
    let fontAttributeKey = UIFontDescriptor.AttributeName.init(rawValue: "NSCTFontUIUsageAttribute")

    if let fontWeight = self.fontDescriptor.fontAttributes[fontAttributeKey] as? String {
      switch fontWeight {
      case "CTFontBoldUsage":
        return UIFont.Weight.bold
      case "CTFontBlackUsage":
        return UIFont.Weight.black
      case "CTFontHeavyUsage":
        return UIFont.Weight.heavy
      case "CTFontUltraLightUsage":
        return UIFont.Weight.ultraLight
      case "CTFontThinUsage":
        return UIFont.Weight.thin
      case "CTFontLightUsage":
        return UIFont.Weight.light
      case "CTFontMediumUsage":
        return UIFont.Weight.medium
      case "CTFontDemiUsage":
        return UIFont.Weight.semibold
      case "CTFontRegularUsage":
        return UIFont.Weight.regular

      default:
        return UIFont.Weight.regular
      }
    }

    return UIFont.Weight.regular
  }
}
