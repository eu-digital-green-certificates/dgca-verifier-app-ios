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
//  COSE.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/14/21.
//

import Foundation
import SwiftCBOR

struct COSE {
  public static func verify(_ cborData: Data, with xHex: String, and yHex: String) -> Bool {
    let decoder = SwiftCBOR.CBORDecoder(input: cborData.uint)

    guard let cbor = try? decoder.decodeItem() else {
      return false
    }
    return verify(cbor, with: xHex, and: yHex)
  }
  public static func verify(_ cborData: Data, with rsa: String) -> Bool {
    let decoder = SwiftCBOR.CBORDecoder(input: cborData.uint)

    guard let cbor = try? decoder.decodeItem() else {
      return false
    }
    return verify(cbor, with: rsa)
  }
  public static func verify(_ cbor: SwiftCBOR.CBOR, with xHex: String, and yHex: String) -> Bool {
    let COSE_TAG = UInt64(18)

    guard
      case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let SwiftCBOR.CBOR.array(array) = cborElement,
      case let SwiftCBOR.CBOR.byteString(signature) = array[3]
    else {
      return false
    }

    let signedPayload: [UInt8] = SwiftCBOR.CBOR.encode(
      [
        "Signature1",
        array[0],
        SwiftCBOR.CBOR.byteString([]),
        array[2]
      ]
    )
    let d = Data(signedPayload)
    let s = Data(signature)
    guard let key = JWK.ecFrom(x: xHex, y: yHex) else {
      return false
    }
    return Signature.verify(s, for: d, with: key)
  }
  public static func verify(_ cbor: SwiftCBOR.CBOR, with derPubKeyB64: String) -> Bool {
    let COSE_TAG = UInt64(18)

    guard
      case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let SwiftCBOR.CBOR.array(array) = cborElement,
      case let SwiftCBOR.CBOR.byteString(signature) = array[3]
    else {
      return false
    }

    let signedPayload: [UInt8] = SwiftCBOR.CBOR.encode(
      [
        "Signature1",
        array[0],
        SwiftCBOR.CBOR.byteString([]),
        array[2]
      ]
    )
    let d = Data(signedPayload)
    let s = Data(signature)
    guard let key = X509.pubKey(from: derPubKeyB64) else {
      return false
    }
    return Signature.verify(s, for: d, with: key)
  }
}
