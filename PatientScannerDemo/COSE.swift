//
//  COSE.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/14/21.
//

import Foundation
import SwiftCBOR
//import CryptoKit

struct COSE {
  public static func verify(_ cbor: CBOR, with xHex: String, and yHex: String) -> Bool {
    let COSE_TAG = UInt64(18)

    guard
      case let CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let CBOR.array(array) = cborElement,
      case let CBOR.byteString(signature) = array[3]
    else {
      return false
    }

    let signedPayload: [UInt8] = CBOR.encode(
      [
        "Signature1",
        array[0],
        CBOR.byteString([]),
        array[2]
      ]
    )
    let d = Data(signedPayload)//Data(bytes: signedPayload, count: signedPayload.count)
//    let digest = SHA256.hash(data: signedPayload)
    let s = Data(signature)//Data(bytes: signature, count: signature.count)
    guard let key = JWK.ecFrom(x: xHex, y: yHex) else {
      return false
    }
    return EC256.verify(signature: s, for: d, with: key)
  }
}
