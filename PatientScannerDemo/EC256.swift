//
//  EC256.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/13/21.
//
//  https://developer.apple.com/forums/thread/83136
//

import Foundation

struct EC256 {
  public static func verify(signature: Data, for data: Data, with publicKey: SecKey) -> Bool {
    guard SecKeyIsAlgorithmSupported(publicKey, .verify, .ecdsaSignatureMessageX962SHA256) else {
      print("Pubkey not supported.")
      return false
    }

    let sig = ASN1.signature(from: signature)
    
    // verify signature
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
}
