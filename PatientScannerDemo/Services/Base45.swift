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
//  Base45.swift
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

import Foundation


let BASE45_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

extension String {
  enum Base45Error: Error {
    case Base64InvalidCharacter
    case Base64InvalidLength
  }

  public func fromBase45() throws -> Data  {
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
    for i in stride(from: 0, to: d.count, by: 3) {
      if (d.count - i < 2) {
        throw Base45Error.Base64InvalidLength
      }
      var x: UInt32 = UInt32(d[i]) + UInt32(d[i + 1]) * 45
      if (d.count - i >= 3) {
        x += 45 * 45 * UInt32(d[i + 2])
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
