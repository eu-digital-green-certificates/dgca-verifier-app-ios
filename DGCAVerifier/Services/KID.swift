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
//  KID.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/22/21.
//
        

import Foundation

typealias KidBytes = [UInt8]

struct KID {
  public static func string(from kidBytes: KidBytes) -> String {
    return Data(kidBytes.prefix(8)).base64EncodedString()
  }
  public static func from(_ encodedCert: String) -> KidBytes {
    guard
      let data = Data(base64Encoded: encodedCert)
    else {
      return []
    }
    return .init(SHA256.digest(input: data as NSData).uint.prefix(8))
  }
}
