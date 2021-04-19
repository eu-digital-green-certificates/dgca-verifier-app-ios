//
//  CBOR.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/15/21.
//

import Foundation
import SwiftCBOR

struct CBOR {
  static func unwrap(data: Data) -> (SwiftCBOR.CBOR?, SwiftCBOR.CBOR?) {
    let COSE_TAG = UInt64(18)
    let decoder = SwiftCBOR.CBORDecoder(input: data.uint)

    guard
      let cbor = try? decoder.decodeItem(),
      case let SwiftCBOR.CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let SwiftCBOR.CBOR.array(array) = cborElement,
      case let SwiftCBOR.CBOR.byteString(protectedBytes) = array[0],
      let protected = try? SwiftCBOR.CBOR.decode(protectedBytes),
      case let SwiftCBOR.CBOR.byteString(payloadBytes) = array[2],
      let payload = try? SwiftCBOR.CBOR.decode(payloadBytes)
    else {
      return (nil, nil)
    }
    return (payload, protected)
  }

  public static func payload(from data: Data) -> SwiftCBOR.CBOR? {
    return unwrap(data: data).0
  }

  public static func header(from data: Data) -> SwiftCBOR.CBOR? {
    return unwrap(data: data).1
  }

  public static func kid(from data: Data) -> [UInt8]? {
    let COSE_PHDR_KID = SwiftCBOR.CBOR.unsignedInt(4)

    guard
      let protected = unwrap(data: data).1,
      case let SwiftCBOR.CBOR.map(protectedMap) = protected
    else {
      return nil
    }
    let kid = protectedMap[COSE_PHDR_KID] ?? .null
    switch kid {
    case let .utf8String(str):
      #if DEBUG
      print("Warning, CBOR not fully compliant!! Trying to understand it as Hex String. Fallback utf8 (which is against the spec).")
      #else
      return nil
      #endif
      return Data(hexString: str)?.uint ?? str.data(using: .utf8)?.uint
    case let .byteString(uint):
      return uint
    default:
      return nil
    }
  }
}

extension SwiftCBOR.CBOR {
  func toString() -> String {
    switch self {
    case let .byteString(val):
      return String(describing: val)
    case let .unsignedInt(val):
      return "\(val)"
    case let .negativeInt(val):
      return "-\(val)"
    case let .utf8String(val):
      return "\"\(val)\""
    case let .array(vals):
      var s = ""
      for val in vals {
        s += (s.isEmpty ? "" : ", ") + val.toString()
      }
      return "[\(s)]"
    case let .map(vals):
      var s = ""
      for pair in vals {
        var key = pair.key.toString()
        key = key.trimmingCharacters(in: ["\""])
        key = "\"\(key)\""
        s += (s.isEmpty ? "" : ", ") + "\(key): \(pair.value.toString())"
      }
      return "{\(s)}"
    case let .boolean(val):
      return String(describing: val)
    case .null:
      return "null"
    case .undefined:
      return "null"
    case let .float(val):
      return "\(val)"
    case let .double(val):
      return "\(val)"
    case let .date(val):
      return "\"\(val.isoString)\""
    default:
      return "\"unsupported data\""
    }
  }
}
