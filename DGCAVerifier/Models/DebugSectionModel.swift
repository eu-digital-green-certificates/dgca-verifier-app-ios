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
//  DebugSectionModel.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import Foundation
import SwiftDGC

enum DebugSectionType {
  case verification
  case general
  case raw
}

final class DebugSectionModel {
  var sectionType: DebugSectionType = .verification
  var sectionName: String {
    switch sectionType {
    case .verification:
      return "Verification"
    case .general:
      return "General"
    case .raw:
      return "Raw Data"
    }
  }
  var hCert: HCert
  var isExpanded = false
  
  var numberOfItems: Int {
    if !isExpanded {
      return 1
    }
    switch sectionType {
    case .verification:
      return 2
    case .general:
      return 2
    case .raw:
      return 2
    }
  }
    
  init(hCert: HCert, sectionType: DebugSectionType) {
    self.hCert = hCert
    self.sectionType = sectionType
  }
    
  func update(hCert: HCert) {
    self.hCert = hCert
  }
}
