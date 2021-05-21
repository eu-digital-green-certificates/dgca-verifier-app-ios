//
//  RecoveryValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct RecoveryValidityCheck {
    
    func checkRecoveryDate(_ hcert: HCert) -> Bool {
        let recoveryStartDays = LocalData.sharedInstance.settings.filter{ $0.name == "recovery_cert_start_day"}.first?.value ?? "0"
        let recoveryEndDays = LocalData.sharedInstance.settings.filter{ $0.name == "recovery_cert_end_day"}.first?.value ?? "0"
        let recoveryValidFromTimeAsString = hcert.statement.info.filter{ $0.header == l10n("recovery.valid-from")}.first?.content
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        let recoveryValidFromTime = dateFormatter.date(from: recoveryValidFromTimeAsString!)
        let recoveryValidityStart = Calendar.current.date(byAdding: .day, value: Int(recoveryStartDays) ?? 0, to: recoveryValidFromTime!)!
        let recoveryValidityEnd = Calendar.current.date(byAdding: .day, value: Int(recoveryEndDays) ?? 0, to: recoveryValidFromTime!)!
        return (Date() > recoveryValidityStart && Date() < recoveryValidityEnd)
    }
}
