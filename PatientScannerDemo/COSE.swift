//
//  COSE.swift
//  PatientScannerDemo
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
  public static func verify(_ cbor: SwiftCBOR.CBOR, with rsa: String) -> Bool {
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
    guard let key = X509.rsa(from: rsa) else {
      return false
    }
    return Signature.verify(s, for: d, with: key)
  }
}
