//
//  COSE.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/14/21.
//

import Foundation
import SwiftCBOR
import CryptoKit

struct COSE {
  public static func verify(_ cbor: CBOR, with xHex: String, and yHex: String) -> Bool {
    let COSE_TAG = UInt64(18)
    let COSE_PHDR_SIG = CBOR.unsignedInt(1)

    guard
      case let CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let CBOR.array(array) = cborElement,
      case let CBOR.byteString(protectedBytes) = array[0],
      case let CBOR.map(unprotected) = array[1],
      case let CBOR.byteString(payloadBytes) = array[2],
      case let CBOR.byteString(signature) = array[3],
      let protected = try? CBOR.decode(protectedBytes),
      let payload = try? CBOR.decode(payloadBytes),
      case let CBOR.map(protectedMap) = protected,
      let sig = protectedMap[COSE_PHDR_SIG]
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
    let d = Data(bytes: signedPayload, count: signedPayload.count)
    let digest = SHA256.hash(data: signedPayload)
    guard
      let signatureForData = try? P256.Signing.ECDSASignature(rawRepresentation: signature)
    else {
      return false
    }

    struct TE : CustomStringConvertible {
      var description: String
      let kid : String
      //let coord : Array()
    }

    let x = Data(hexString: xHex)?.uint ?? []
    let y = Data(hexString: yHex)?.uint ?? []
    let rawk: [UInt8] = [04] + x + y
    let _ = (unprotected, sig, d, payload) // unused

    if
      rawk.count == 32+32+1,
      let publicKey = try? P256.Signing.PublicKey(x963Representation: rawk),
      publicKey.isValidSignature(signatureForData, for: digest)
    {
      return true
    }
    return false
  }
}
