//
//  CBOR.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/15/21.
//

import Foundation
import SwiftCBOR

struct CBOR {
  public static func payload(from data: Data) -> SwiftCBOR.CBOR? {
    let COSE_TAG = UInt64(18)
    let decoder = SwiftCBOR.CBORDecoder(input: data.uint)

    guard
      let cbor = try? decoder.decodeItem(),
      case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let SwiftCBOR.CBOR.array(array) = cborElement,
      case let SwiftCBOR.CBOR.byteString(payloadBytes) = array[2],
      let payload = try? SwiftCBOR.CBOR.decode(payloadBytes)
    else {
      return nil
    }
    return payload
  }

  public static func kid(from data: Data) -> [UInt8]? {
    let COSE_TAG = UInt64(18)
    let COSE_PHDR_KID = SwiftCBOR.CBOR.unsignedInt(4)
    let decoder = SwiftCBOR.CBORDecoder(input: data.uint)

    guard
      let cbor = try? decoder.decodeItem(),
      case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let SwiftCBOR.CBOR.array(array) = cborElement,
      case let SwiftCBOR.CBOR.byteString(protectedBytes) = array[0],
      let protected = try? SwiftCBOR.CBOR.decode(protectedBytes),
      case let SwiftCBOR.CBOR.map(protectedMap) = protected
    else {
      return nil
    }
    let kid = protectedMap[COSE_PHDR_KID] ?? .null
    switch kid {
    case let .utf8String(str):
      return str.encode()
    case let .byteString(str):
      return str
    default:
      return nil
    }
  }
}
