//
//  RecoveryValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct RecoveryValidityCheck {
    
    func isRecoveryValid(_ hcert: HCert) -> Status {
        guard let validFrom = hcert.recoveryDateFrom else { return .notValid }
        guard let validUntil = hcert.recoveryDateUntil else { return .notValid }
        
        guard let validityStart = validFrom.toRecoveryDate else { return .notValid }
        guard let validityEnd = validUntil.toRecoveryDate else { return .notValid }
    
        guard let currentDate = Date.startOfDay else { return .notValid }
        
        return Validator.validate(currentDate, from: validityStart, to: validityEnd)
    }
}
