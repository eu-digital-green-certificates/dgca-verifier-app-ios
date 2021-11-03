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
//  LocalDataKeeper.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import SwiftDGC
import SwiftyJSON

struct LocalData: Codable {
  var encodedPublicKeys = [String: [String]]()
  var resumeToken: String?
  var lastFetchRaw: Date?
  var lastFetch: Date {
    get {
      lastFetchRaw ?? .init(timeIntervalSince1970: 0)
    }
    set {
      lastFetchRaw = newValue
    }
  }
  var config = Config.load()
  var lastLaunchedAppVersion = ""
}

class LocalDataKeeper {
  static let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"
  lazy var storage = SecureStorage<LocalData>(fileName: "secure")
  
  var localData: LocalData = LocalData()
  
  func add(encodedPublicKey: String) {
    let kid = KID.from(encodedPublicKey)
    let kidStr = KID.string(from: kid)

    let list = localData.encodedPublicKeys[kidStr] ?? []
    if list.contains(encodedPublicKey) {
      return
    }
    localData.encodedPublicKeys[kidStr] = list + [encodedPublicKey]
  }
  
  func keep(resumeToken: String) {
    localData.resumeToken = resumeToken
  }
  
  func save() {
    storage.save(localData)
  }
  
  func initialize(completion: @escaping () -> Void) {
    storage.loadOverride(fallback: localData) { [unowned self]  success in
      guard var result = success else { return }
          
      let format = l10n("log.keys-loaded")
       DGCLogger.logInfo(String.localizedStringWithFormat(format, result.encodedPublicKeys.count))
      if result.lastLaunchedAppVersion != Self.appVersion {
        result.config = self.localData.config
      }
      self.localData = result
      completion()
    }
    CoreManager.publicKeyEncoder = LocalDataKeyEncoder()
  }
  
  var versionedConfig: JSON {
    if localData.config["versions"][Self.appVersion].exists() {
      return localData.config["versions"][Self.appVersion]
    } else {
      return localData.config["versions"]["default"]
    }
  }
}

class LocalDataKeyEncoder: PublicKeyStorageDelegate {
  func getEncodedPublicKeys(for kidStr: String) -> [String] {
    LocalStorage.dataKeeper.localData.encodedPublicKeys[kidStr] ?? []
  }
}