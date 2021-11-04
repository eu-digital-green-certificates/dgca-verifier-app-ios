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
//  ValueSetsDataKeeper.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 25.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

class ValueSetsDataKeeper {
  let storage = SecureStorage<ValueSetsDataStorage>(fileName: "valueSets_secure")
  var valueSetsData: ValueSetsDataStorage = ValueSetsDataStorage()

  func add(valueSet: CertLogic.ValueSet) {
    let list = valueSetsData.valueSets
    if list.contains(where: { savedValueSet in
      savedValueSet.valueSetId == valueSet.valueSetId
    }) {
      return
    }
    valueSetsData.valueSets.append(valueSet)
  }

  func save() {
    storage.save(valueSetsData)
  }

  func deleteValueSetWithHash(hash: String) {
    valueSetsData.valueSets = valueSetsData.valueSets.filter { $0.hash != hash }
  }
    
  func isValueSetExistWithHash(hash: String) -> Bool {
    let list = valueSetsData.valueSets
    return list.contains(where: { $0.hash == hash })
  }
    
  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: valueSetsData) { success in
      guard let result = success else {
        completion()
        return
      }
        
      let format = l10n("log.valueSets")
      DGCLogger.logInfo(String.localizedStringWithFormat(format, result.valueSets.count))
      self.valueSetsData = result
      completion()
    }
  }
}

// MARK: ValueSets for External Parameters
extension ValueSetsDataKeeper {
  public func getValueSetsForExternalParameters() -> Dictionary<String, [String]> {
    var returnValue = Dictionary<String, [String]>()
    valueSetsData.valueSets.forEach { valueSet in
        let keys = Array(valueSet.valueSetValues.keys)
        returnValue[valueSet.valueSetId] = keys
    }
    return returnValue
  }
}