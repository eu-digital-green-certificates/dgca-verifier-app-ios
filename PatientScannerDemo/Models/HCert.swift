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

struct InfoSection {
  var header: String
  var content: String
}

struct HCert {
  mutating func parseBodyV1() -> Bool {
    let schema = JSON(parseJSON: EU_DGC_SCHEMA_V1).dictionaryObject!
    let bodyDict = body.dictionaryObject!

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
//    body = JSON(parseJSON: """
//      {
//        "vac" : [
//          {
//            "seq" : 1,
//            "lot" : "C22-862FF-001",
//            "dis" : "840539006",
//            "adm" : "Vaccination centre Vienna 23",
//            "vap" : "1119305005",
//            "mep" : "EU\\/1\\/20\\/1528",
//            "tot" : 2,
//            "aut" : "ORG-100030215",
//            "dat" : "2021-02-18",
//            "cou" : "AT"
//          },
//          {
//            "seq" : 2,
//            "lot" : "C22-H62FF-010",
//            "dis" : "840539006",
//            "adm" : "Vaccination centre Vienna 23",
//            "vap" : "1119305005",
//            "mep" : "EU\\/1\\/20\\/1528",
//            "tot" : 2,
//            "aut" : "ORG-100030215",
//            "dat" : "2021-03-12",
//            "cou" : "AT"
//          }
//        ],
//        "cert" : {
//          "id" : "01AT42196560275230427402470256520250042",
//          "is" : "Ministry of Health, Austria",
//          "vr" : "v1.0",
//          "vf" : "2021-04-04",
//          "vu" : "2021-10-04",
//          "co" : "AT"
//        },
//        "sub" : {
//          "gen" : "female",
//          "dob" : "1998-02-26",
//          "id" : [
//            {
//              "i" : "12345ABC-321",
//              "t" : "PPN"
//            }
//          ],
//          "gn" : "Gabriele",
//          "fn" : "Musterfrau"
//        }
//      }
//""")
  }

  var header: JSON
  var body: JSON

  var fullName: String {
    let first = body["sub"]["gn"].string ?? ""
    let last = body["sub"]["fn"].string ?? ""
    return "\(first) \(last)"
  }

  var info: [InfoSection] {
    [
      InfoSection(header: "Test", content: "Test Test")
    ]
  }
}
