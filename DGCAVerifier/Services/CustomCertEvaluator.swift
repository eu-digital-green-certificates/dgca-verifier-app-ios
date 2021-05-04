//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  CustomCertEvaluator.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 5/4/21.
//  
        

import Foundation
import Alamofire
import SwiftDGC

class CustomCertEvaluator: ServerTrustEvaluating {
  static let DO_DEBUG_PRINTOUTS = false
  static let trustList = [
    // lets-encrypt-e2.der:
    "J6qdORIaZFkjocoOWDyGAI6W1hD9leksny2DCIzp6BY=",
    // lets-encrypt-r3-cross-signed.der:
    "WhPjrFuxeyg9KK8laj3ZQc9SGYz6m91uB9263f2LWXo=",
    // lets-encrypt-e1.der:
    "TDpoKUoYLApI07ClfAc7p6Y/wIXsOhob9LyXNQMqsRk=",
    // lets-encrypt-r3.der:
    "WhPjrFuxeyg9KK8laj3ZQc9SGYz6m91uB9263f2LWXo=",
    // lets-encrypt-r4.der:
    "FMg5EuXMBgDDksSP3R0pWSGNx6yLMMV4RKzheoOSWYA=",
    // lets-encrypt-r4-cross-signed.der:
    "FMg5EuXMBgDDksSP3R0pWSGNx6yLMMV4RKzheoOSWYA=",
    // DigiCertTLSRSASHA2562020CA1.der:
    "Ef6tLK887tpTdkiVkSG7ioXCgNEJsbIgKcAU+dxTTag=",
  ]

  class EvaluationError: Error {}

  func evaluate(_ trust: SecTrust, forHost host: String) throws {
    let hashes: [String] = trust.af.publicKeys.compactMap { key in
      guard
        let der = X509.derKey(for: key)
      else {
        return nil
      }
      return SHA256.digest(input: der as NSData).base64EncodedString()
    }
    for hash in hashes {
      if Self.trustList.contains(hash) {
        #if DEBUG && targetEnvironment(simulator)
        print("SSL Pubkey matches. ✅")
        #endif
        return
      }
    }
    #if !DEBUG || !targetEnvironment(simulator)
    throw EvaluationError()
    #endif
    print("\nFATAL: None of the hashes matched our public keys! These files were loaded locally:")
    printHashes()
    print("\nThis is the chain of the endpoint you are trying to reach:", "\n" + hashes.joined(separator: "\n"))
    print("The last one is a root certificate, it is best to use an intermediate instead, because they are rotated more frequently.")
  }

  func printHashes() {
    guard
      let path = Bundle.main.resourcePath,
      let contents = try? FileManager.default.contentsOfDirectory(atPath: path)
    else {
      return
    }

    let certs = contents.filter {
      $0.hasSuffix(".der")
    }
    for cert in certs {
      let fileURL = URL(fileURLWithPath: path + "/\(cert)")
      guard let fileContents = try? Data(contentsOf: fileURL) else {
        continue
      }
      let encoded = fileContents.base64EncodedString()
      guard
        let key = X509.pubKey(from: encoded),
        let keyData = X509.derPubKey(for: key)
      else {
        return
      }
      print("// \(cert):")
      debugPrint(SHA256.digest(input: keyData as NSData).base64EncodedString(), terminator: ",\n")
    }
  }
}
