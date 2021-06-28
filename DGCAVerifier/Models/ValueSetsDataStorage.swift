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
//  File.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 25.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON
import CertLogic

struct ValueSetsDataStorage: Codable {
  static var sharedInstance = ValueSetsDataStorage()

  var valueSets = [CertLogic.ValueSet]()
  var lastFetchRaw: Date?
  var lastFetch: Date {
    get {
      lastFetchRaw ?? .init(timeIntervalSince1970: 0)
    }
    set(value) {
      lastFetchRaw = value
    }
  }
  var config = Config.load()

  mutating func add(valueSet: CertLogic.ValueSet) {
    let list = valueSets
    if list.contains(where: { savedValueSet in
      savedValueSet.valueSetId == valueSet.valueSetId
    }) {
      return
    }
    valueSets.append(valueSet)
  }

  public func save() {
    Self.storage.save(self)
  }

  public mutating func deleteValueSetWithHash(hash: String) {
    self.valueSets = self.valueSets.filter { $0.hash != hash }
  }
  public func isValueSetExistWithHash(hash: String) -> Bool {
    let list = valueSets
    return list.contains(where: { valueSet in
      valueSet.hash == hash
    })
  }
  static let storage = SecureStorage<ValueSetsDataStorage>(fileName: "valueSets_secure")

  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: ValueSetsDataStorage.sharedInstance) { success in
      guard let result = success else {
        return
      }
      let format = l10n("log.valueSets")
      print(String.localizedStringWithFormat(format, result.valueSets.count))
      ValueSetsDataStorage.sharedInstance = result
      completion()
    }
  }
}

// MARK: ValueSets for External Parameters
extension ValueSetsDataStorage {
  public func getValueSetsForExternalParameters() -> Dictionary<String, [String]> {
    var returnValue = Dictionary<String, [String]>()
    valueSets.forEach { valueSet in
      if let keys: [String] = Array(valueSet.valueSetValues.keys) as? [String] {
        returnValue[valueSet.valueSetId] = keys
      }
    }
    return returnValue
  }
}
