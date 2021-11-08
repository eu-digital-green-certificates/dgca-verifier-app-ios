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
//  CountryDataManager.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 22.06.2021.
//  
import Foundation
import SwiftDGC
import SwiftyJSON

class CountryDataManager {
  lazy var storage = SecureStorage<CountryDataStorage>(fileName: SharedConstants.countryStorageName)
  lazy var countryData: CountryDataStorage = CountryDataStorage()
  
  func add(country: CountryModel) {
    if !countryData.countryCodes.contains(where: { $0.code == country.code }) {
      countryData.countryCodes.append(country)
    }
  }
  
  func update(country: CountryModel) {
    guard let countryFromDB = countryData.countryCodes.filter({ $0.code == country.code }).first else { return }
    countryFromDB.debugModeEnabled = country.debugModeEnabled
    save()
  }

  func save() {
    storage.save(countryData)
  }

  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: countryData) { [unowned self] value in
      guard let result = value else {
        completion()
        return
      }
        
      let format = l10n("log.country")
      DGCLogger.logInfo(String.localizedStringWithFormat(format, result.countryCodes.count))
      self.countryData = result
      self.save()
      completion()
    }
  }
}
