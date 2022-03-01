//
//  FilterError.swift
//  
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation

enum FilterError: Error {
	case invalidParameters
	case invalidSize
	case notEnoughMemory
	case invalidEncoding
	case unknownError
	case unsupportedCryptoFunction
	case hashError
	case filledFilter
	case tooManyHashRounds
	case cannotLoadData
}
