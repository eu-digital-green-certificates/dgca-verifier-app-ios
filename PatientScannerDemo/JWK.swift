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
  public static func ecFrom(x: String, y: String) -> SecKey? {
    var xBytes: Data?
    var yBytes: Data?
    if (x + y).count == 128 {
      xBytes = Data(hexString: x)
      yBytes = Data(hexString: y)
    } else {
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
      xBytes = Data(base64Encoded: xStr)
      yBytes = Data(base64Encoded: yStr)
    }

    // Now this bytes we have to append such that [0x04 , /* xBytes */, /* yBytes */]
    // Initial byte for uncompressed y as Key.
    let keyData = NSMutableData.init(bytes: [0x04], length: 1)
    keyData.append(xBytes ?? Data())
    keyData.append(yBytes ?? Data())
    let attributes: [String: Any] = [
      String(kSecAttrKeyType): kSecAttrKeyTypeEC,
      String(kSecAttrKeyClass): kSecAttrKeyClassPublic,
      String(kSecAttrKeySizeInBits): 256,
      String(kSecAttrIsPermanent): false
    ]
    var error: Unmanaged<CFError>?
    let keyReference = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
    let errorString = error?.takeUnretainedValue().localizedDescription ?? "Something went wrong"
    error?.release()
    guard
      let key = keyReference
    else {
      print(errorString)
      return nil
    }

    return key
  }
}
