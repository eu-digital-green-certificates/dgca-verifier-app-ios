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
//  RulesDataManager.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import CertLogic

class RulesDataManager {
  lazy var storage = SecureStorage<RulesDataStorage>(fileName: SharedConstants.rulesStorageName)
  var localData: RulesDataStorage = RulesDataStorage()
  
  func add(rule: CertLogic.Rule) {
    if !localData.rules.contains(where: { $0.identifier == rule.identifier && $0.version == rule.version }) {
      localData.rules.append(rule)
    }
  }

  func save(completion: @escaping DataCompletionHandler) {
    storage.save(localData, completion: completion)
  }

  func deleteRuleWithHash(hash: String) {
    localData.rules = localData.rules.filter { $0.hash != hash }
  }
    
  func isRuleExistWithHash(hash: String) -> Bool {
    return localData.rules.contains(where: { $0.hash == hash })
  }
  
  func loadLocallyStoredData(completion: @escaping DataCompletionHandler) {
    storage.loadStoredData(fallback: localData) { [unowned self] data in
      guard let result = data else {
        completion(.failure(DataOperationError.noInputData))
        return
      }

      let format = "%d rules loaded."
      DGCLogger.logInfo(String(format: format, result.rules.count))
      self.localData = result
      self.save(completion: completion)
    }
  }
}
