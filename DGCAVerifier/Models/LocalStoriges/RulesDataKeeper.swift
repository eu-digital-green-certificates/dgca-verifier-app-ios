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
//  RulesDataKeeper.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

class RulesDataKeeper {
  let storage = SecureStorage<RulesDataStorage>(fileName: "rules_secure")
  var rulesData: RulesDataStorage = RulesDataStorage()
  
  func add(rule: CertLogic.Rule) {
    if !rulesData.rules.contains(where: { $0.identifier == rule.identifier && $0.version == rule.version }) {
      rulesData.rules.append(rule)
    }
  }

  func save() {
    storage.save(rulesData)
  }

  func deleteRuleWithHash(hash: String) {
    rulesData.rules = rulesData.rules.filter { $0.hash != hash }
  }
    
  func isRuleExistWithHash(hash: String) -> Bool {
    return rulesData.rules.contains(where: { $0.hash == hash })
  }
  
  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: rulesData) { [unowned self] value in
      guard let result = value else {
        completion()
        return
      }
          
      let format = l10n("log.rules")
      DGCLogger.logInfo(String.localizedStringWithFormat(format, result.rules.count))
      self.rulesData = result
      completion()
    }
  }
}
