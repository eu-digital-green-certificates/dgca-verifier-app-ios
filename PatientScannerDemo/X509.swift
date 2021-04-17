//
//  X509.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/17/21.
//

import Foundation

struct X509 {
  public static func pubKey(from b64EncodedCert: String) -> SecKey? {
    guard
      let encodedCertData = Data(base64Encoded: b64EncodedCert),
      let cert = SecCertificateCreateWithData(nil, encodedCertData as CFData),
      let publicKey = SecCertificateCopyKey(cert)
    else {
      return nil
    }
    return publicKey
  }
}
