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
        guard let recoveryStartDays = LocalData.sharedInstance.getFirstSetting(withName: "recovery_cert_start_day") else {
            return .notValid
        }
        guard let recoveryEndDays = LocalData.sharedInstance.getFirstSetting(withName: "recovery_cert_end_day") else {
            return .notValid
        }
        guard let recoveryValidFromTimeAsString = hcert.statement.info.filter({ $0.header == l10n("recovery.valid-from")}).first?.content else {
            return .notValid
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        let recoveryValidFromTime = dateFormatter.date(from: recoveryValidFromTimeAsString)
        let recoveryValidityStart = Calendar.current.date(byAdding: .day, value: Int(recoveryStartDays) ?? 0, to: recoveryValidFromTime!)!
        let recoveryValidityEnd = Calendar.current.date(byAdding: .day, value: Int(recoveryEndDays) ?? 0, to: recoveryValidFromTime!)!
        return (Date() >= recoveryValidityStart && Date() <= recoveryValidityEnd) ? .valid : .expired
    }
}
