//
//  Base45.swift
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

import Foundation

extension String {
  enum Base45Error: Error {
    case Base64InvalidCharacter
    case Base64InvalidLength
  }

  public func fromBase45() throws -> Data  {
    let BASE45_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
    var d = Data()
    var o = Data()

    for c in self.uppercased() {
      if let at = BASE45_CHARSET.firstIndex(of: c) {
        let idx  = BASE45_CHARSET.distance(from: BASE45_CHARSET.startIndex, to: at)
        d.append(UInt8(idx))
      } else {
        throw Base45Error.Base64InvalidCharacter
      }
    }
    for i in stride(from:0, to:d.count, by: 3) {
      if (d.count - i < 2) {
        throw Base45Error.Base64InvalidLength
      }
      var x : UInt32 = UInt32(d[i]) + UInt32(d[i+1])*45
      if (d.count - i >= 3) {
        x += 45 * 45 * UInt32(d[i+2])
        if x >= 256 * 256 {
          throw Base45Error.Base64InvalidCharacter
        }
        o.append(UInt8(x / 256))
      }
      o.append(UInt8(x % 256))
    }
    return o
  }
}

extension String {
  subscript(i: Int) -> String {
    return String(self[index(startIndex, offsetBy: i)])
  }
}

extension Data {
  public func toBase45()->String {
    let BASE45_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
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
