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
// https://stackoverflow.com/a/55558641/2585092

import Foundation
import Compression

func decompressString(_ data: Data) -> String {
  return String(decoding: decompress(data), as: UTF8.self)
}

func decompress(_ data: Data) -> Data {
  let size = 4 * data.count + 8 * 1024
  let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
  let result = data.subdata(in: 2 ..< data.count).withUnsafeBytes ({
    let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                         data.count - 2, nil, COMPRESSION_ZLIB)
    return Data(bytes: buffer, count:read)
  }) as Data
  buffer.deallocate()
  return result
}
