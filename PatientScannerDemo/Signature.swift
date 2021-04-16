//
//  EC256.swift
//  PatientScannerDemo
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
