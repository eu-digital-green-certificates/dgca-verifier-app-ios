//
//  HCert+Vaccine.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import SwiftDGC

extension HCert {
    
    private var currentDosesNumberKey       : String { "dn" }
    private var totalDosesNumberKey         : String { "sd" }
    private var medicalProductKey           : String { "mp" }
    private var dateKey                     : String { "dt" }
    
    var currentDosesNumber: Int? {
        body["v"].array?.map{ $0[currentDosesNumberKey] }.first?.int
    }
    
    var totalDosesNumber: Int? {
        body["v"].array?.map{ $0[totalDosesNumberKey] }.first?.int
    }

    var medicalProduct: String? {
        body["v"].array?.map{ $0[medicalProductKey] }.first?.string
    }
    
    var vaccineDate: String? {
        body["v"].array?.map{ $0[dateKey] }.first?.string
    }

}
