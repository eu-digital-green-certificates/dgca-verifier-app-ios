//
//  JWK.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/13/21.
//
//  https://medium.com/@vaibhav.pmeshram/creating-and-dismantling-ec-key-in-swift-f5bde8cb633f
//

import Foundation

struct JWK {
  public func from(x: String, y: String) -> SecKey? {
    var xStr = x // Base64 Formatted data
    var yStr = y

    xStr = xStr.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while xStr.count % 4 != 0 {
      xStr.append("=")
    }
    yStr = yStr.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while yStr.count % 4 != 0 {
      yStr.append("=")
    }
    guard
      let xBytes = Data(base64Encoded: xStr),
      let yBytes = Data(base64Encoded: yStr)
    else { return nil }

    // Now this bytes we have to append such that [0x04 , /* xBytes */, /* yBytes */, /* dBytes */]
    // Initial byte for uncompressed y as Key.
    let keyData = NSMutableData.init(bytes: [0x04], length: [0x04].count)
    keyData.append(xBytes)
    keyData.append(yBytes)
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrIsPermanent as String: false
    ]
    var error: Unmanaged<CFError>?
    guard
      let keyReference = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
    else { return nil }

    return keyReference
  }
}
