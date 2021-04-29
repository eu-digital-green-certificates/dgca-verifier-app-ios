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
//  TestResult.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/28/21.
//  
        

import Foundation
import SwiftyJSON

enum TestResult: String {
  case detected = "260373001"
  case notDetected = "260415000"
}

struct TestEntry: HCertEntry {
  var info: [InfoSection] {
    [
      InfoSection(header: "Time of Sampling", content: sampleTime.dateTimeString),
      InfoSection(header: "Test Result", content: resultNegative ? "Not Detected" : "Detected ⚠️"),
    ]
  }

  var isValid: Bool {
    resultNegative && sampleTime < Date()
  }

  enum Fields: String {
    case diseaseTargeted = "tg"
    case type = "tt"
    case sampleTime = "sc"
    case result = "tr"
    case testCenter = "tc"
    case country = "co"
    case issuer = "is"
    case uvci = "ci"
  }

  init?(body: JSON) {
    guard
      let diseaseTargeted = body[Fields.diseaseTargeted.rawValue].string,
      let type = body[Fields.type.rawValue].string,
      let sampleTimeStr = body[Fields.sampleTime.rawValue].string,
      let sampleTime = Date(rfc3339DateTimeString: sampleTimeStr),
      let result = body[Fields.result.rawValue].string,
      let testCenter = body[Fields.testCenter.rawValue].string,
      let country = body[Fields.country.rawValue].string,
      let issuer = body[Fields.issuer.rawValue].string,
      let uvci = body[Fields.uvci.rawValue].string
    else {
      return nil
    }
    self.diseaseTargeted = diseaseTargeted
    self.type = type
    self.sampleTime = sampleTime
    self.resultNegative = (TestResult(rawValue: result) == .notDetected)
    self.testCenter = testCenter
    self.country = country
    self.issuer = issuer
    self.uvci = uvci
  }

  var diseaseTargeted: String
  var type: String
  var sampleTime: Date
  var resultNegative: Bool
  var testCenter: String
  var country: String
  var issuer: String
  var uvci: String
}
