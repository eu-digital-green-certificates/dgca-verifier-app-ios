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
//  LocalData.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import SwiftDGC
import SwiftyJSON

class LocalData: Codable {
  static let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?"
  static var sharedInstance = LocalData()
  static let storage = SecureStorage<LocalData>(fileName: "secure")

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
  var lastLaunchedAppVersion = LocalData.appVersion

  func add(encodedPublicKey: String) {
    let kid = KID.from(encodedPublicKey)
    let kidStr = KID.string(from: kid)

    let list = encodedPublicKeys[kidStr] ?? []
    if list.contains(encodedPublicKey) {
      return
    }
    encodedPublicKeys[kidStr] = list + [encodedPublicKey]
  }

  static func set(resumeToken: String) {
    sharedInstance.resumeToken = resumeToken
  }

  func save() {
    Self.storage.save(self)
  }

  static func initialize(completion: @escaping () -> Void) {
      storage.loadOverride(fallback: LocalData.sharedInstance) { success in
      guard let result = success else { return }
          
      let format = l10n("log.keys-loaded")
       DGCLogger.logInfo(String.localizedStringWithFormat(format, result.encodedPublicKeys.count))
      if result.lastLaunchedAppVersion != Self.appVersion {
        result.config = LocalData.sharedInstance.config
      }
      LocalData.sharedInstance = result
      completion()
    }
    VerificationManager.sharedManager.publicKeyEncoder = LocalDataKeyEncoder.instance
  }
  
  var versionedConfig: JSON {
    if config["versions"][Self.appVersion].exists() {
      return config["versions"][Self.appVersion]
    } else {
      return config["versions"]["default"]
    }
  }
}

class LocalDataKeyEncoder: PublicKeyStorageDelegate {
  static let instance = LocalDataKeyEncoder()
  
  func getEncodedPublicKeys(for kidStr: String) -> [String] {
    LocalData.sharedInstance.encodedPublicKeys[kidStr] ?? []
  }
}
