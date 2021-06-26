//
//  TestValidityCheck.swift
//  Verifier
//
//  Created by Davide Aliti on 21/05/21.
//

import Foundation
import SwiftDGC

struct TestValidityCheck {
    
    private let resultKey = "test.test-result"
    private let isNegativeKey = "test.result.negative"
    
    private let startHoursKey = "rapid_test_start_hours"
    private let endHoursKey = "rapid_test_end_hours"
    
    func isTestNegative(_ hcert: HCert) -> Status {
        guard let isNegative = hcert.testNegative else { return .notValid }
        return isNegative ? .valid : .notValid
    }
    
    func isTestDateValid(_ hcert: HCert) -> Status {
        guard let startHours = LocalData.getSetting(from: startHoursKey) else { return .notValid }
        guard let endHours = LocalData.getSetting(from: endHoursKey) else { return .notValid }
        guard let start = startHours.intValue else { return .notValid }
        guard let end = endHours.intValue else { return .notValid }

        guard let dateString = hcert.testDate else { return .notValid }
        guard let dateTime = dateString.toTestDate else { return .notValid }
        guard let validityStart = dateTime.add(start, ofType: .hour) else { return .notValid }
        guard let validityEnd = dateTime.add(end, ofType: .hour) else { return .notValid }
        
        let currentDate = Date()
        return Validator.validate(currentDate, from: validityStart, to: validityEnd)
    }
    
    func isTestValid(_ hcert: HCert) -> Status {
        let testValidityResults = [isTestNegative(hcert), isTestDateValid(hcert)]
        return testValidityResults.first(where: {$0 != .valid}) ?? .valid
    }
    
}
