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
    if SecKeyIsAlgorithmSupported(publicKey, .verify, .ecdsaSignatureMessageX962SHA256) {
      return verifyEC(signature, for: data, with: publicKey)
    }
    if SecKeyIsAlgorithmSupported(publicKey, .verify, .rsaSignatureMessagePSSSHA256) {
      return verifyRSA(signature, for: data, with: publicKey)
    }
    return false
  }

  static func verifyEC(_ signature: Data, for data: Data, with publicKey: SecKey) -> Bool {
    let sig = ASN1.signature(from: signature)

    var error: Unmanaged<CFError>?
    let result = SecKeyVerifySignature(
      publicKey,
      .ecdsaSignatureMessageX962SHA256,
      data as NSData,
      sig as NSData,
      &error
    )
    if let err = error?.takeUnretainedValue().localizedDescription {
      print(err)
    }
    error?.release()

    return result
  }

  static func verifyRSA(_ signature: Data, for data: Data, with publicKey: SecKey) -> Bool {
    let sig = signature

    var error: Unmanaged<CFError>?
    let result = SecKeyVerifySignature(
      publicKey,
      .rsaSignatureMessagePSSSHA256,
      data as NSData,
      sig as NSData,
      &error
    )
    if let err = error?.takeUnretainedValue().localizedDescription {
      print(err)
    }
    error?.release()

    return result
  }
}
