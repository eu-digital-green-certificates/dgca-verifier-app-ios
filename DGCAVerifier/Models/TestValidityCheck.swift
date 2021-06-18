//
//  TestValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct TestValidityCheck {
    func isTestNegative(_ hcert: HCert) -> Status {
        return hcert.statement.info.filter{ $0.header == l10n("test.test-result")}.first?.content == l10n("test.result.negative") ? .valid : .notValid
    }
    
    func isTestDateValid(_ hcert: HCert) -> Status {
        guard let testStartHours = LocalData.sharedInstance.getFirstSetting(withName: "rapid_test_start_hours") else {
            return .notValid
        }
        guard let testEndHours = LocalData.sharedInstance.getFirstSetting(withName: "rapid_test_end_hours") else {
            return .notValid
        }
        guard let testSampleDateTimeAsString = (hcert.statement.info.filter{ $0.header == l10n("test.sample-date-time")}).first?.content else {
            return .notValid
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        let testSampleDateTime = dateFormatter.date(from: testSampleDateTimeAsString.replacingOccurrences(of: " (UTC)", with: ""))
        let testValidityStart = Calendar.current.date(byAdding: .hour, value: Int(testStartHours) ?? 0, to: testSampleDateTime!)!
        let testValidityEnd = Calendar.current.date(byAdding: .hour, value: Int(testEndHours) ?? 0, to: testSampleDateTime!)!
        
        switch Date() {
        case ..<testValidityStart:
                return .future
        case testValidityStart...testValidityEnd:
            return .valid
        default:
            return .expired
        }
    }
    
    func isTestValid(_ hcert: HCert) -> Status {
        let testValidityResults = [isTestNegative(hcert), isTestDateValid(hcert)]
        return testValidityResults.first(where: {$0 != .valid}) ?? .valid
    }
}
