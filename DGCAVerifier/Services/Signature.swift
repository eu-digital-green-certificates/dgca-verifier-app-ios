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
//  EC256.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/13/21.
//
//  https://developer.apple.com/forums/thread/83136
//

import Foundation

struct Signature {
  public static func verify(_ signature: Data, for data: Data, with publicKey: SecKey) -> Bool {
    var signature = signature
    var alg: SecKeyAlgorithm

    if SecKeyIsAlgorithmSupported(publicKey, .verify, .ecdsaSignatureMessageX962SHA256) {
      alg = .ecdsaSignatureMessageX962SHA256
      signature = ASN1.signature(from: signature)
    } else if SecKeyIsAlgorithmSupported(publicKey, .verify, .rsaSignatureMessagePSSSHA256) {
      alg = .rsaSignatureMessagePSSSHA256
    } else {
      return false
    }

    var error: Unmanaged<CFError>?
    let result = SecKeyVerifySignature(
      publicKey,
      alg,
      data as NSData,
      signature as NSData,
      &error
    )
    if let err = error?.takeUnretainedValue().localizedDescription {
      print(err)
    }
    error?.release()

    return result
  }
}
