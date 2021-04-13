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
    // create a certificate object
//    let certURL = URL(fileURLWithPath: #file).appendingPathComponent("../../../cert.der").standardized
//    let certData = NSData(contentsOf: certURL)
    var error: Unmanaged<CFError>?

//
//    // create a SecCertificate object
//
//    var secCertificate: SecCertificate?
//
//    if let certData = certData {
//      secCertificate = SecCertificateCreateWithData(nil, certData)
//    }
//
//    // create a SecTrust object
//    var trustCert: SecTrust?
//    let secTrustError = SecTrustCreateWithCertificates(secCertificate!, nil, &trustCert)
//    guard secTrustError == errSecSuccess else {
//      return false
//    }

    // read in OpenSSL generated signature

//    let openSSLSigURL = URL(fileURLWithPath: #file).appendingPathComponent("../../../signature.bin").standardized
    let openSSLSig = signature


    guard
//      let trustCert = trustCert,
      let targetsSignedData = data as NSData?
    else { return false }

    // obtain public key from SecTrust object
//    let publicKey = SecTrustCopyPublicKey(trustCert)

    // ensure key is of the correct algorithm

    guard SecKeyIsAlgorithmSupported(publicKey, .verify, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256) else {
      return false
    }

    // verify signature
    if SecKeyVerifySignature(publicKey, SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256, targetsSignedData, openSSLSig as NSData, &error) {
      print("Verify Success!")
      return true
    }
    else {
      print("Verify Failed!")
      print(error?.takeUnretainedValue().localizedDescription ?? "Something went wrong")
      return false
    }
  }
}

