//
//  Validator.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 26/06/21.
//

import Foundation

struct Validator {
    
    public static func validate(_ current: Date, from validityStart: Date, to validityEnd: Date) -> Status {
        switch current {
        case ..<validityStart:
            return .future
        case validityStart...validityEnd:
            return .valid
        default:
            return .expired
        }
    }
    
}
