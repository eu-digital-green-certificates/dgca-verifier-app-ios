//
//  Extensions.swift
//  
//
//  Created by Igor Khomiak on 03.02.2022.
//

import Foundation
import BigInt

extension Double {
	var bytes: [UInt8] {
		withUnsafeBytes(of: self, Array.init)
	}
}

extension UInt16 {
	var bytes: [UInt8] {
		withUnsafeBytes(of: self, Array.init)
	}
}

extension UInt32 {
	var bytes: [UInt8] {
		withUnsafeBytes(of: self, Array.init)
	}
}

extension Int32 {
	var bytes: [UInt8] {
		withUnsafeBytes(of: self, Array.init)
	}
}

public extension Bytes {
	
	func toLong() -> UInt32 {
		let diff = 4-self.count
		var array: [UInt8] = [0, 0, 0, 0]
		
		for idx in diff...3 {
			array[idx] = self[idx-diff]
		}
		
		return  UInt32(bigEndian: Data(array).withUnsafeBytes { $0.pointee })
	}
	
	func toFloat() -> Float {
		let bigEndianValue = self.withUnsafeBufferPointer {
			$0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
		}
		let bitPattern = UInt32(bigEndian: bigEndianValue)
		return Float(bitPattern: bitPattern)
	}
}
