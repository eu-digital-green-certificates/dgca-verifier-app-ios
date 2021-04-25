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
//  SwiftCBOR.CBOR.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import SwiftCBOR

extension SwiftCBOR.CBOR {
  func toString() -> String {
    switch self {
    case let .byteString(val):
      let fallBack = "[" + val.map {
        "\($0)"
      }.joined(separator: ", ") + "]"
      if
        let child = try? SwiftCBOR.CBOR.decode(val),
        case .map(_) = child
      {
        return child.toString()
      }
      return fallBack
    case let .unsignedInt(val):
      return "\(val)"
    case let .negativeInt(val):
      return "-\(val + 1)"
    case let .utf8String(val):
      return "\"\(val)\""
    case let .array(vals):
      var s = ""
      for val in vals {
        s += (s.isEmpty ? "" : ", ") + val.toString()
      }
      return "[\(s)]"
    case let .map(vals):
      var s = ""
      for pair in vals {
        var key = pair.key.toString()
        key = key.trimmingCharacters(in: ["\""])
        key = "\"\(key)\""
        s += (s.isEmpty ? "" : ", ") + "\(key): \(pair.value.toString())"
      }
      return "{\(s)}"
    case let .boolean(val):
      return String(describing: val)
    case .null:
      return "null"
    case .undefined:
      return "null"
    case let .float(val):
      return "\(val)"
    case let .double(val):
      return "\(val)"
    case let .date(val):
      return "\"\(val.isoString)\""
    default:
      return "\"unsupported data\""
    }
  }
}
