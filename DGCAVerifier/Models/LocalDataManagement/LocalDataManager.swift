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
//  LocalDataManager.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import SwiftDGC
import SwiftyJSON

class LocalDataManager {
  lazy var storage = SecureStorage<LocalData>(fileName: SharedConstants.dataStorageName)
  lazy var localData: LocalData = LocalData()
  
  func add(encodedPublicKey: String) {
    let kid = KID.from(encodedPublicKey)
    let kidStr = KID.string(from: kid)

    let list = localData.encodedPublicKeys[kidStr] ?? []
    if !list.contains(encodedPublicKey) {
      localData.encodedPublicKeys[kidStr] = list + [encodedPublicKey]
    }
  }
  
  func merge(other: JSON) {
    localData.config.merge(other: other)
  }
  
  func save() {
    storage.save(localData)
  }
  
  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: localData) { [unowned self]  success in
      guard let result = success else {
        completion()
        return
      }
          
      let format = l10n("log.keys-loaded")
      DGCLogger.logInfo(String.localizedStringWithFormat(format, result.encodedPublicKeys.count))
      if result.lastLaunchedAppVersion != DataCenter.appVersion {
        result.config = self.localData.config
        result.lastLaunchedAppVersion = DataCenter.appVersion
      }
      self.localData = result
      self.save()
      CoreManager.publicKeyEncoder = LocalDataKeyEncoder()
      completion()
    }
  }
  
  var versionedConfig: JSON {
    if localData.config["versions"][DataCenter.appVersion].exists() {
      return localData.config["versions"][DataCenter.appVersion]
    } else {
      return localData.config["versions"]["default"]
    }
  }
}

class LocalDataKeyEncoder: PublicKeyStorageDelegate {
  func getEncodedPublicKeys(for kidStr: String) -> [String] {
    DataCenter.localDataManager.localData.encodedPublicKeys[kidStr] ?? []
  }
}