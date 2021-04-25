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
//  SecureStorage.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  


import Foundation

struct SecureStorage {
  static let documents: URL! = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  static let path: URL! = URL(string: documents.absoluteString + "secure.db")

  public static func load(completion: @escaping (Bool) -> Void) {
    if !FileManager.default.fileExists(atPath: path.path) {
      save()
      if FileManager.default.fileExists(atPath: path.path) {
        load(completion: completion)
      } else {
        completion(false)
      }
      return
    }

    guard
      let data = read(),
      let key = Enclave.symmetricKey
    else {
      completion(false)
      return
    }
    Enclave.decrypt(data: data, with: key) { decrypted, err in
      guard
        let decrypted = decrypted,
        err == nil,
        let data = try? JSONDecoder().decode(LocalData.self, from: decrypted)
      else {
        completion(false)
        return
      }
      LocalData.sharedInstance = data
      completion(true)
    }
  }

  public static func save() {
    guard
      let data = try? JSONEncoder().encode(LocalData.sharedInstance),
      let key = Enclave.symmetricKey,
      let encrypted = Enclave.encrypt(data: data, with: key).0
    else {
      return
    }
    print("write", write(data: encrypted))
  }

  static func write(data: Data) -> Bool {
    do {
      try data.write(to: path)
    } catch {
      return false
    }
    return true
  }

  static func read() -> Data? {
    do {
      let savedData = try Data(contentsOf: path)
      return savedData
    } catch {
      return nil
    }
  }
}
