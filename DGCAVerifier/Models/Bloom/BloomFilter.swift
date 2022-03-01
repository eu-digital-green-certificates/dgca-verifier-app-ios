//
//  BloomFilter.swift
//
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation
import BigInt

public class BloomFilter {
	private var array: [Int32] = []
	// each element has 4 bytes: MemoryLayout<Int32>.size == 4 Bytes;
	
	/**
	 n -> number of items in the filter   (n = ceil(m / (-k / log(1 - exp(log(p) / k)))))
	 p -> probabilty of false positives   (p = pow(1 - exp(-k / (m / n)), k))
	 m -> number of bits in filter           (m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
	 k -> number of hash functions      (k = round((m / n) * log(2));)
	 */
	
	// private var byteSize: Int
	public var probRate: Float = 0.0
	private var version: UInt16 = 1
	
	private var numberOfHashes: UInt8 = 0
	private var numBits: UInt32 = 0
	
	public var currentElementAmount: Int = 0
	public var definedElementAmount: Int = 0
	public var usedHashFunction: UInt8 = 0
	
	// CONST
	private let NUM_BYTES = MemoryLayout<UInt32>.size  // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
	private let NUM_BITS = 8                           // number of bits to use for one byte
	private let NUM_FORMAT: UInt32 = UInt32(MemoryLayout<UInt32>.size * 8)
	
    public init(data: Data) {
		self.array = []
        readFrom(data: data)
	}
	
	public init?(memorySize: Int, hashesNumber: UInt8, elementsNumber: Int) {
		guard memorySize > 0 && hashesNumber > 0 && elementsNumber > 0 else { return nil }
		
		self.numberOfHashes = hashesNumber
		
		let size = (memorySize / NUM_BYTES) + (memorySize % NUM_BYTES)
		self.numBits = UInt32(size) * NUM_FORMAT
		
		self.probRate = BloomFilter.calcProbValue(numBits: numBits, numberOfElements: elementsNumber, numberOfHashes: hashesNumber)
		self.definedElementAmount = elementsNumber
		self.array = Array(repeating: 0, count: Int(size))
	}
	
	public init?(elementsNumber: Int, probabilityRate: Float) {
		guard elementsNumber > 0 && probabilityRate > 0.0 else { return nil }
		
		self.probRate = probabilityRate
		self.definedElementAmount = elementsNumber
		
		let bitsNumber = BloomFilter.calcMValue(n: elementsNumber, p: probabilityRate)
		let byteAmount = (bitsNumber / NUM_BITS) + 1
		let size = (byteAmount / NUM_BYTES) + (byteAmount % NUM_BYTES)
		
		self.numBits = UInt32(size) * NUM_FORMAT
		
		let hashesNumber = BloomFilter.calcKValue(m: numBits, n: elementsNumber)
		self.numberOfHashes = hashesNumber
		
		self.array = Array(repeating: 0, count: size)
	}
	
	public func add(element: Data) {
		for hashIndex in 0..<self.numberOfHashes {
			let index = BloomFilter.calcIndex(element: element, index: UInt8(hashIndex), numberOfBits: self.numBits).asMagnitudeBytes().toLong()
			
			let bytePos = index / NUM_FORMAT
			let normIndex = index - bytePos * NUM_FORMAT
			let pattern = Int32.min >>> normIndex
			self.array[Int(bytePos)] = array[Int(bytePos)] | pattern
		}
		currentElementAmount += 1
		if currentElementAmount >= definedElementAmount {
			print("Warning: currentElementAmount exceed of definedElementAmount")
		}
	}
	
	public func mightContain(element: Data) -> Bool {
		for i in 0..<self.numberOfHashes {
            let index = BloomFilter.calcIndex(element: element, index: UInt8(i), numberOfBits: self.numBits).asMagnitudeBytes().toLong()
			let bytePos = UInt64(UInt32(index) / UInt32(self.NUM_FORMAT))
			let index2: UInt32 = UInt32(index - UInt32(UInt32(bytePos) * UInt32(NUM_FORMAT)))
			let pattern = Int32.min >>> index2
			if (self.array[Int(bytePos)] & pattern) == pattern {
				return true
			}
		}
		return false
	}
	
	public func resetElements() {
		for ind in 0..<array.count {
			array[ind] = 0
		}
		currentElementAmount = 0
	}
	
	public func getData() -> [Int32] {
		return array
	}
	
	public static func calcIndex(element: Data, index: UInt8, numberOfBits: UInt32) -> BInt {
		let hash = BloomFilter.hash(data:element, hashFunction: HashFunctions.SHA256, seed: index)
		let hashInt = BInt(signed: Array(hash))
		let nBytes = withUnsafeBytes(of: numberOfBits.bigEndian, Array.init)
		let dividedValue = BInt(signed:nBytes)
		let result = hashInt.mod(dividedValue)
		return result
	}
	
	public func readFrom(data: Data) {
		self.version = data[0..<2].reversed().withUnsafeBytes {$0.load(as: UInt16.self)}
		self.numberOfHashes = data[2..<3].withUnsafeBytes {$0.load(as: UInt8.self)}
		self.usedHashFunction = data[3..<4].withUnsafeBytes {$0.load(as: UInt8.self)}
		
		self.probRate = [UInt8](data[4..<8]).toFloat()
		
		let declaredAmount = data[8..<12].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
		self.definedElementAmount =  Int(declaredAmount)
		
		let currentAmount = data[12..<16].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
		self.currentElementAmount = Int(currentAmount)
		let elementsCount = data[16..<20].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
		array.removeAll()
		
		var startIndex = 20
		for _ in 0..<elementsCount {
			guard startIndex <= data.count else { break }
			
			let newElement = data[startIndex..<startIndex + 4].reversed().withUnsafeBytes {$0.load(as: Int32.self)}
			array.append(newElement)
			startIndex += 4
		}
		
		self.numBits =  UInt32(array.count) * NUM_FORMAT
	}
	
	public func writeToData() -> Data  {
		var data = Data(count: 24 + array.count * 4)
		data[0..<2] = Data(version.bytes.reversed())
		data[2..<4] = Data([usedHashFunction, numberOfHashes])
		data[4..<8] = Data(probRate.bytes.reversed())
		data[8..<12] = Data(Int32(definedElementAmount).bytes.reversed())
		data[12..<16] =  Data(Int32(currentElementAmount).bytes.reversed())
		let dataLen = Int32(array.count)
		data[16..<20] = Data(dataLen.bytes.reversed())
		
		var startIndex = 20
		for ind in 0..<array.count {
			data[startIndex..<startIndex+4] = Data(Int32(array[ind]).bytes.reversed())
			startIndex += 4
		}
		return data
	}
	
	func convert(_ bytes: [UInt8]) -> Float {
		var val: Float
		// guard bytes.count == MemoryLayout<Double>.size else { return -1.0 }
		val = bytes.withUnsafeBytes {
			return $0.load(as: Float.self)
		}
		return Float(val);
	}
	
	func _convertToBytes<T>(_ value: T, withCapacity capacity: Int) -> [UInt8] {
		var mutableValue = value
		return withUnsafePointer(to: &mutableValue) {
			return $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
				return Array(UnsafeBufferPointer(start: $0, count: capacity))
			}
		}
	}
}

extension FloatingPoint {
	init?(_ bytes: [UInt8]) {
		guard bytes.count == MemoryLayout<Self>.size else { return nil }
		self = bytes.withUnsafeBytes {
			return $0.load(fromByteOffset: 0, as: Self.self)
		}
	}
}

extension Float {
	var bytes: [UInt8] {
		withUnsafeBytes(of: self, Array.init)
	}
}


infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int32, rhs: UInt32) -> Int32 {
	return Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
}

public extension BloomFilter  {
	
	static func calcProbValue(numBits: UInt32, numberOfElements n: Int, numberOfHashes k: UInt8) -> Float {
		return Float(pow(1.0 - exp(Float(-Int8(k)) / (Float)(numBits / 8) / Float(n)), Float(k)))
	}
	
	static func calcMValue(n: Int, p: Float) -> Int {
		return Int(ceil((Float(n) * log(p)) / log(1 / pow(2, log(2)))))
	}
	
	static func calcKValue(m: UInt32, n: Int) -> UInt8 {
		return UInt8(max(1, round(Double(m) / Double(n) * log(2))))
	}
}
