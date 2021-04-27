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

struct LocalData: Codable {
  static var sharedInstance = LocalData()

  var encodedPublicKeys = [String: String]()
  var resumeToken: String?
  var lastFetch_: Date?
  var lastFetch: Date {
    get {
      lastFetch_ ?? .init(timeIntervalSince1970: 0)
    }
    set(v) {
      lastFetch_ = v
    }
  }

  mutating func add(encodedPublicKey: String) {
    let kid = KID.from(encodedPublicKey)
    let kidStr = KID.string(from: kid)

    encodedPublicKeys[kidStr] = encodedPublicKey
  }

  static func set(resumeToken: String) {
    sharedInstance.resumeToken = resumeToken
  }

  public func save() {
    Self.storage.save(self)
  }

  static let storage = SecureStorage<LocalData>()
}
