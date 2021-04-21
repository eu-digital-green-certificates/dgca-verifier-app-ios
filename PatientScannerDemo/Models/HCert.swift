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
  case gender
  case dateOfBirth
  case testStatements
  case vaccineStatements
  case recoveryStatements
  case personIdentifiers
  case identifierType = "t"
  case identifierCountry = "c"
  case identifierValue = "i"
  case vaccineShotNo = "seq"
  case vaccineShotTotal = "tot"
}

enum HCertType: String {
  case test = "Test"
  case vaccineOne = "First Vaccine Shot"
  case vaccineTwo = "Last Vaccine Shot"
  case recovery = "Recovery"
}

enum HCertValidity {
  case valid
  case invalid
}

let identifierNames: [String: String] = [
  "PP": "Passport Number",
  "NN": "National Person Identifier",
  "CZ": "Citizenship Card Number",
  "HC": "Health Card Number",
]

let attributeKeys: [AttributeKey: [String]] = [
  .firstName: ["sub", "gn"],
  .lastName: ["sub", "fn"],
  .gender: ["sub", "gen"],
  .dateOfBirth: ["sub", "dob"],
  .personIdentifiers: ["sub", "id"],
  .testStatements: ["tst"],
  .vaccineStatements: ["vac"],
  .recoveryStatements: ["rec"],
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

  func get(_ attribute: AttributeKey) -> JSON {
    var object = body
    for key in attributeKeys[attribute] ?? [] {
      object = object[key]
    }
    return object
  }

  var info: [InfoSection] {
    var info = [
      InfoSection(header: "Certificate Type", content: type.rawValue),
    ] + personIdentifiers
    if let date = dateOfBirth {
      info += [
        InfoSection(header: "Date of Birth", content: date.localDateString),
      ]
    }
    return info
  }

  var header: JSON
  var body: JSON

  var fullName: String {
    let first = get(.firstName).string ?? ""
    let last = get(.lastName).string ?? ""
    return "\(first) \(last)"
  }

  var dateOfBirth: Date? {
    guard let dateString = get(.dateOfBirth).string else {
      return nil
    }
    return Date(dateString: dateString)
  }

  var personIdentifiers: [InfoSection] {
    guard let identifiers = get(.personIdentifiers).array else {
      return []
    }
    return identifiers.map {
      let type = $0[AttributeKey.identifierType.rawValue].string ?? ""
      let country = $0[AttributeKey.identifierCountry.rawValue].string
      let value = $0[AttributeKey.identifierValue.rawValue].string ?? ""

      var header = identifierNames[type] ?? "Unknown Identifier"
      if let country = country {
        header += " (\(country))"
      }

      return InfoSection(header: header, content: value)
    }
  }

  var testStatements: [JSON] {
    return get(.testStatements).array ?? []
  }
  var vaccineStatements: [JSON] {
    return get(.vaccineStatements).array ?? []
  }
  var recoveryStatements: [JSON] {
    return get(.recoveryStatements).array ?? []
  }
  var hasLastShot: Bool {
    for statement in vaccineStatements {
      let no = statement[AttributeKey.vaccineShotNo.rawValue].int ?? 1
      let total = statement[AttributeKey.vaccineShotTotal.rawValue].int ?? 2
      if no == total {
        return true
      }
    }
    return false
  }
  var type: HCertType {
    if hasLastShot {
      return .vaccineTwo
    }
    if !vaccineStatements.isEmpty {
      return .vaccineOne
    }
    if !recoveryStatements.isEmpty {
      return .recovery
    }
    return .test
  }
  var isValid: Bool {
    return Int.random(in: 0...9) < 5
  }
  var validity: HCertValidity {
    return isValid ? .valid : .invalid
  }
}
