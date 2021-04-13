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
    var error: Unmanaged<CFError>?
    let targetsSignedData = data as NSData

    guard SecKeyIsAlgorithmSupported(publicKey, .verify, .ecdsaSignatureMessageX962SHA256) else {
      print("Pubkey not supported.")
      return false
    }

    // verify signature
    if SecKeyVerifySignature(
        publicKey,
        SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
        targetsSignedData,
        signature as NSData,
        &error
    ) {
      return true
    }
    else {
      print(error?.takeUnretainedValue().localizedDescription ?? "Something went wrong")
      return false
    }
  }
}

