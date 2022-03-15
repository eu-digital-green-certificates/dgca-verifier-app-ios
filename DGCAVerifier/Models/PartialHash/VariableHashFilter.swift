//
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
//  VariableHashFilter.swift
//  
//
//  Created by Igor Khomiak on 10.03.2022.
//

import Foundation
import SwiftDGC
import BigInt

public enum HashFilterError: Error {
    case illegalArgumentException(reason: String)
}

public class VariableHashFilter {

    private var size: UInt8
    private var version: UInt16 = 1
    private var probRate: Float = 0.0
    private var currentElementAmount: Int = 0
    private var definedElementAmount: Int = 0

    public private(set) var array: [BInt] = []

     /**
     * Partial variable hash list filter initialization
     *
     * @param minSize          minimum size of the filter
     * @param partitionOffset  coordinate = 16, vector = 8, point = 0
     * @param numberOfElements elements in the filter
     * @param propRate         probability rate
     * @see PartitionOffset
     */

    public init?(data: Data) {
        guard !data.isEmpty else { return nil}
                
        self.version = data[0..<2].reversed().withUnsafeBytes {$0.load(as: UInt16.self)}
        
        let bytes = Bytes(data[2..<5])
        let bigEndianValue = bytes.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        let bitPattern = UInt32(bigEndian: bigEndianValue)
        self.probRate = Float(bitPattern: bitPattern)
        
        self.definedElementAmount = data[5..<9].reversed().withUnsafeBytes {$0.load(as: Int.self)}
        self.currentElementAmount = 0
        
        self.size = data[9..<10].withUnsafeBytes {$0.load(as: UInt8.self)}
        let numHashes: Int = (data.count - 11) / Int(size)
        var bigArray: Array<BInt> = Array(repeating: BInt(signed: Bytes()), count: numHashes)
        
        currentElementAmount = 0
        var counter = 11
        while (counter < data.count) {
            let slice: [UInt8] = [UInt8](data[counter..<counter + Int(size)]).reversed()
            bigArray[currentElementAmount] = BInt(signed: slice)
            counter += Int(size)
            currentElementAmount += 1
        }
        self.array = bigArray.sorted()
    }
    
    /**
     * Check whether filter contains dcc hash bytes. It will check bytes depending on the filter size value.
     *
     * @param dccHashBytes byte array of dcc hash.
     * @return true is contains otherwise false
     */
    public func mightContain(element data: Data) -> Bool {
        guard data.count >= size else { return false }
        
        let dccHashBytes: [UInt8] = [UInt8](data)
        let filterSizeBytes: [UInt8] = Array(dccHashBytes[0..<Int(size)])
        let rezult = binarySearch(bigInts: array, from: 0, to: array.count, element: BInt(signed: filterSizeBytes))
        return rezult
    }

    private func binarySearch(bigInts: [BInt], from index1: Int, to index2: Int, element: BInt) -> Bool {
        guard index1 >= index2 else { return false }
        let middle = index1 + (index2 - index1) / 2
        
        if bigInts[middle] == element {
            return true
        }
        
        if bigInts[middle] > element {
            let rezult = binarySearch(bigInts: bigInts, from: index1, to: middle - 1, element: element)
            return rezult
        } else {
            let rezult = binarySearch(bigInts: bigInts, from: middle + 1, to: index2, element: element)
            return rezult
        }
    }
}
