//
//  HCert.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import SwiftyJSON
import JSONSchema

enum ClaimKey: String {
  case HCERT = "-260"
  case EU_DGC_V1 = "1"
}

enum AttributeKey: String {
  case firstName
  case lastName
}

let attributeKeys: [AttributeKey: [String]] = [
  .firstName: ["sub", "gn"],
  .lastName: ["sub", "fn"],
]

struct InfoSection {
  var header: String
  var content: String
}

struct HCert {
  static let supportedPrefixes = [
    "HC1:"
  ]

  mutating func parseBodyV1() -> Bool {
    guard
      let schema = JSON(parseJSON: EU_DGC_SCHEMA_V1).dictionaryObject,
      let bodyDict = body.dictionaryObject
    else {
      return false
    }

    guard
      let validation = try? validate(bodyDict, schema: schema)
    else {
      return false
    }
    #if DEBUG
    if let errors = validation.errors {
      for err in errors {
        print(err.description)
      }
    }
    #else
    if !validation.valid {
      return false
    }
    #endif
    print(header)
    print(body)
    return true
  }

  init?(from cborData: Data) {
    let headerStr = CBOR.header(from: cborData)?.toString() ?? "{}"
    let bodyStr = CBOR.payload(from: cborData)?.toString() ?? "{}"
    header = JSON(parseJSON: headerStr)
    var body = JSON(parseJSON: bodyStr)
    print(body)
    if body[ClaimKey.HCERT.rawValue].exists() {
      body = body[ClaimKey.HCERT.rawValue]
    }
    if body[ClaimKey.EU_DGC_V1.rawValue].exists() {
      self.body = body[ClaimKey.EU_DGC_V1.rawValue]
      if !parseBodyV1() {
        return nil
      }
    } else {
      print("Wrong EU_DGC Version!")
      return nil
    }
  }

  var header: JSON
  var body: JSON

  var fullName: String {
    let first = get(.firstName).string ?? ""
    let last = get(.lastName).string ?? ""
    return "\(first) \(last)"
  }

  func get(_ attribute: AttributeKey) -> JSON {
    var object = body
    for key in attributeKeys[attribute] ?? [] {
      object = object[key]
    }
    return object
  }

  var info: [InfoSection] {
    [
      InfoSection(header: "Test", content: "Test Test")
    ]
  }
}
