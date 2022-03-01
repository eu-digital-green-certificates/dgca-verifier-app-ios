//
//  BloomFilter+Hasher.swift
//
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation
import CryptoKit

extension BloomFilter {
    /**
     Takes either a string or a byte array and hashes it with the given hashFunction
     */
    public class func hash(data: Data, hashFunction: HashFunctions, seed: UInt8) -> Data {
        let seedBytes = Data(withUnsafeBytes(of: seed, Array.init))
        var hashingData = data
        hashingData.append(seedBytes)
        
        let resultData = SHA256.sha256(data: hashingData)
        return resultData
    }
}

private func md5(data : NSData) -> Data {
    return Data() //not implemented
}

public enum HashFunctions {
    case SHA256
    case MD5
}
