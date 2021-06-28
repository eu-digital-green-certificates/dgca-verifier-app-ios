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
//  CountryDataStorage.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON

struct CountryDataStorage: Codable {
  static var sharedInstance = CountryDataStorage()

  var countryCodes = [CountryModel]()
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

  mutating func add(country: CountryModel) {
    let list = countryCodes
    if list.contains(where: { savedCountry in
      savedCountry.code == country.code
    }) {
      return
    }
    countryCodes.append(country)
  }

  public func save() {
    Self.storage.save(self)
  }

  static let storage = SecureStorage<CountryDataStorage>(fileName: "country_secure")

  static func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: CountryDataStorage.sharedInstance) { success in
      guard let result = success else {
        return
      }
      let format = l10n("log.country")
      print(String.localizedStringWithFormat(format, result.countryCodes.count))
      CountryDataStorage.sharedInstance = result
      completion()
    }
  }
}
