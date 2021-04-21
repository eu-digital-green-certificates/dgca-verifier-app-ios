//
//  Data+Base45.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/21/21.
//

import Foundation


extension Data {
  public func toBase45()->String {
    var o = String()
    for i in stride(from:0, to:self.count, by: 2) {
      if (self.count - i > 1) {
        let x : Int = (Int(self[i])<<8) + Int(self[i+1])
        let e : Int = x / (45*45)
        let x2 : Int = x % (45*45)
        let d : Int = x2 / 45
        let c : Int = x2 % 45
        o.append(BASE45_CHARSET[c])
        o.append(BASE45_CHARSET[d])
        o.append(BASE45_CHARSET[e])
      } else {
        let x2 : Int = Int(self[i])
        let d : Int = x2 / 45
        let c : Int = x2 % 45
        o.append(BASE45_CHARSET[c])
        o.append(BASE45_CHARSET[d])
      }
    }
    return o
  }
}
