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
//  Asn1Encoder.swift
//  OegvatClient
//
//  Created by Christian Kollmann on 23.04.20.
//

import Foundation

public class ASN1 {
  // 32 for ES256
  public static func signature(from data: Data, _ digestLengthInBytes: Int = 32) -> Data {
    let sigR = encodeIntegerToAsn1(data.prefix(data.count - digestLengthInBytes))
    let sigS = encodeIntegerToAsn1(data.suffix(digestLengthInBytes))
    let tagSequence: UInt8 = 0x30
    return Data([tagSequence] + [UInt8(sigR.count + sigS.count)] + sigR + sigS)
  }

  private static func encodeIntegerToAsn1(_ data: Data) -> Data {
    let firstBitIsSet: UInt8 = 0x80 // would be decoded as a negative number
    let tagInteger: UInt8 = 0x02
    if (data.first! >= firstBitIsSet) {
      return Data([tagInteger] + [UInt8(data.count + 1)] + [0x00] + data)
    } else if (data.first! == 0x00) {
      return encodeIntegerToAsn1(data.dropFirst())
    } else {
      return Data([tagInteger] + [UInt8(data.count)] + data)
    }
  }

}
