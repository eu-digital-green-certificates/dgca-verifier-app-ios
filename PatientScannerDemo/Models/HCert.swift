//
//  HCert.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import SwiftyJSON
import JSONSchema

struct HCert {
  init(from cborData: Data) {
    let headerStr = CBOR.header(from: cborData)?.toString() ?? "{}"
    let bodyStr = CBOR.payload(from: cborData)?.toString() ?? "{}"
    header = JSON(parseJSON: headerStr)
    body = JSON(parseJSON: bodyStr)

    let schema = JSON(parseJSON: EU_DGC_SCHEMA).dictionaryObject!
    let bodyDict = body.dictionaryObject!

    let validation = try? validate(bodyDict, schema: schema)
    if let errors = validation?.errors {
      for err in errors {
        print(err.description)
      }
    }
  }

  var header: JSON
  var body: JSON

  var fullName: String {
    let first = body["-259"]["1"]["sub"]["gn"].string ?? ""
    let last = body["-259"]["1"]["sub"]["fn"].string ?? ""
    return "\(first) \(last)"
  }
}
