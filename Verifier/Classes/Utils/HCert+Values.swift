//
//  HCert+Values.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import SwiftDGC

public extension HCert {
    
    private var currentDosesNumberKey       : String { "dn" }
    private var totalDosesNumberKey         : String { "sd" }
    private var dateKey                     : String { "dt" }
    private var issuerKey                   : String { "is" }
    
    var currentDosesNumber: Int? {
        self.body["v"].array?.map{ $0[currentDosesNumberKey] }.first?.int
    }
    
    var totalDosesNumber: Int? {
        self.body["v"].array?.map{ $0[totalDosesNumberKey] }.first?.int
    }

}
