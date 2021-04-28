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

struct SecureDB: Codable {
  let data: Data
  let signature: Data
}

struct SecureStorage<T: Codable> {
  let documents: URL! = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  var path: URL! { URL(string: documents.absoluteString + "secure.db") }
  let secureStorageKey = Enclave.loadOrGenerateKey(with: "secureStorageKey")

  /**
   Loads encrypted db and overrides it with an empty one if that fails.
   */
  public func loadOverride(fallback: T, completion: ((T?) -> Void)? = nil) {
    load { result in
      if result != nil {
        completion?(result)
        return
      }
      save(fallback) { _ in
        load(completion: completion)
      }
    }
  }

  public func load(completion: ((T?) -> Void)? = nil) {
    if !FileManager.default.fileExists(atPath: path.path) {
      completion?(nil)
      return
    }

    guard
      let (data, signature) = read(),
      let key = secureStorageKey,
      Enclave.verify(data: data, signature: signature, with: key).0
    else {
      completion?(nil)
      return
    }
    Enclave.decrypt(data: data, with: key) { decrypted, err in
      guard
        let decrypted = decrypted,
        err == nil,
        let data = try? JSONDecoder().decode(T.self, from: decrypted)
      else {
        completion?(nil)
        return
      }
      completion?(data)
    }
  }

  public func save(_ instance: T, completion: ((Bool) -> Void)? = nil) {
    guard
      let data = try? JSONEncoder().encode(instance),
      let key = secureStorageKey,
      let encrypted = Enclave.encrypt(data: data, with: key).0
    else {
      completion?(false)
      return
    }
    Enclave.sign(data: encrypted, with: key) { signature, err in
      guard
        let signature = signature,
        err == nil
      else {
        completion?(false)
        return
      }
      let success = write(data: encrypted, signature: signature)
      completion?(success)
    }
  }

  func write(data: Data, signature: Data) -> Bool {
    guard
      let rawData = try? JSONEncoder().encode(SecureDB(data: data, signature: signature)),
      let _ = try? rawData.write(to: path)
    else {
      return false
    }
    return true
  }

  func read() -> (Data, Data)? {
    guard
      let rawData = try? Data(contentsOf: path, options: [.uncached]),
      let result = try? JSONDecoder().decode(SecureDB.self, from: rawData)
    else {
      return nil
    }
    return (result.data, result.signature)
  }
}
