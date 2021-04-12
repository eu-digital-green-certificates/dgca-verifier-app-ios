// https://stackoverflow.com/a/55558641/2585092

import Foundation
import Compression

func decompressString(_ data: Data) -> String {
  let size = 4 * data.count
  let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
  let result = data.subdata(in: 2 ..< data.count).withUnsafeBytes ({
    let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                         data.count - 2, nil, COMPRESSION_ZLIB)
    return String(decoding: Data(bytes: buffer, count:read), as: UTF8.self)
  }) as String
  buffer.deallocate()
  return result
}

func decompress(_ data: Data) -> Data {
  let size = 4 * data.count
  let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
  let result = data.subdata(in: 2 ..< data.count).withUnsafeBytes ({
    let read = compression_decode_buffer(buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                                         data.count - 2, nil, COMPRESSION_ZLIB)
    return Data(bytes: buffer, count:read)
  }) as Data
  buffer.deallocate()
  return result
}
