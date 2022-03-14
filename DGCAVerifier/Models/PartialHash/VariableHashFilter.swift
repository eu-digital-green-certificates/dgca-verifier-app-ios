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
        
        let byteArray = [UInt8](data)
        self.size = byteArray[0]
        let numHashes: Int = (byteArray.count - 1) / Int(size)
        var bigArray: Array<BInt> = Array(repeating: BInt(signed: Bytes()), count: numHashes)
        
        var hashNumCounter = 0
        var counter = 1
        while (counter < byteArray.count) {
            let sliceArray = Array(byteArray[counter..<counter + Int(size)])
            bigArray[hashNumCounter] = BInt(signed: sliceArray)
            counter += Int(size)
            hashNumCounter += 1
        }
        self.array = bigArray
    }
    /**
     * Check whether filter contains dcc hash bytes. It will check bytes depending on the filter size value.
     *
     * @param dccHashBytes byte array of dcc hash.
     * @return true is contains otherwise false
     */
    public func mightContain(element: Data) -> Bool {
        guard element.count >= size else { return false }
        
        let dccHashBytes: [UInt8] = [UInt8](element)
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
