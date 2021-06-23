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
        guard let recoveryValidFromTimeAsString = hcert.statement.info.filter({ $0.header == l10n("recovery.valid-from")}).first?.content else {
            return .notValid
        }
        
        guard let recoveryValidUntilTimeAsString = hcert.statement.info.filter({ $0.header == l10n("recovery.valid-until")}).first?.content else {
            return .notValid
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        
        guard let recoveryValidityStart = dateFormatter.date(from: recoveryValidFromTimeAsString) else {
            return .notValid
        }
        guard let recoveryValidityEnd = dateFormatter.date(from: recoveryValidUntilTimeAsString) else {
            return .notValid
        }
    
        switch Date() {
        case ..<recoveryValidityStart:
                return .future
        case recoveryValidityStart...recoveryValidityEnd:
            return .valid
        default:
            return .expired
        }
    }
}
