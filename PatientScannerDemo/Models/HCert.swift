//
//  HCert.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import SwiftyJSON

struct HCert {
  init(from cborData: Data) {
    let headerStr = CBOR.header(from: cborData)?.toString() ?? "{}"
    let bodyStr = CBOR.payload(from: cborData)?.toString() ?? "{}"
    header = JSON(parseJSON: headerStr)
    body = JSON(parseJSON: bodyStr)
  }

  var header: JSON
  var body: JSON
}
