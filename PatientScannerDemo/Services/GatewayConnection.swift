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
//  GatewayConnection.swift
//  PatientScannerDemo
//  
//  Created by Yannick Spreen on 4/24/21.
//  
        

import Foundation
import Alamofire

struct GatewayConnection {
  static let serverURI = "https://dgca-verifier-service.cfapps.eu10.hana.ondemand.com/"
  static let updateEndpoint = "signercertificateUpdate"
  static let statusEndpoint = "signercertificateStatus"

  public static func fetchCert(resume resumeToken: String? = nil) {
    AF.request(serverURI + updateEndpoint).response {
      guard
        case let .success(result) = $0.result,
        let response = result,
        let responseStr = String(data: response, encoding: .utf8),
        let pubKey = X509.pubKey(from: responseStr),
        let headers = $0.response?.headers,
        let responseKid = headers["x-kid"]
      else {
        return
      }
      let kid = KID.from(responseStr)
      let kidStr = KID.string(from: kid)
      if kidStr != responseKid {
        return
      }
      print(pubKey)
    }
  }
}
