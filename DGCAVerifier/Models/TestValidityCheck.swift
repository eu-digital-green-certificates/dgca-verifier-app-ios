//
//  TestValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct TestValidityCheck {
    func checkTestResult(_ hcert: HCert) -> Bool {
        return hcert.statement.info.filter{ $0.header == l10n("test.test-result")}.first?.content == l10n("test.result.negative")
    }
    
    func checkTestDate(_ hcert: HCert) -> Bool {
        let testStartHours = LocalData.sharedInstance.settings.filter{ $0.name == "rapid_test_start_hours"}.first?.value ?? "0"
        let testEndHours = LocalData.sharedInstance.settings.filter{ $0.name == "rapid_test_end_hours"}.first?.value ?? "0"
        let testSampleDateTimeAsString = hcert.statement.info.filter{ $0.header == l10n("test.sample-date-time")}.first?.content
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        let testSampleDateTime = dateFormatter.date(from: testSampleDateTimeAsString!.replacingOccurrences(of: " (UTC)", with: ""))
        let testValidityStart = Calendar.current.date(byAdding: .hour, value: Int(testStartHours) ?? 0, to: testSampleDateTime!)!
        let testValidityEnd = Calendar.current.date(byAdding: .hour, value: Int(testEndHours) ?? 0, to: testSampleDateTime!)!
        return (Date() > testValidityStart && Date() < testValidityEnd)
    }
}
