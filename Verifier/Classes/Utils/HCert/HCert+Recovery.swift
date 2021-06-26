//
//  HCert+Recovery.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 26/06/21.
//

import SwiftDGC

extension HCert {
    
    private var dateFromKey     : String { "df" }
    private var dateUntilKey    : String { "du" }
    
    var recoveryDateFrom: String? {
        body["r"].array?.map{ $0[dateFromKey] }.first?.string
    }
    
    var recoveryDateUntil: String? {
        body["r"].array?.map{ $0[dateUntilKey] }.first?.string
    }
    
}
