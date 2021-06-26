//
//  HCert+Test.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 26/06/21.
//

import SwiftDGC

extension HCert {
    
    private var dateKey       : String { "sc" }
    private var resultKey     : String { "tr" }
    private var detected      : String { "260373001" }
    private var notDetected   : String { "260415000" }
    
    var testDate: String? {
        body["t"].array?.map{ $0[dateKey] }.first?.string
    }
    
    var testNegative: Bool? {
        testResult == notDetected
    }
    
    var testResult: String? {
        body["t"].array?.map{ $0[resultKey] }.first?.string
    }
    
}
