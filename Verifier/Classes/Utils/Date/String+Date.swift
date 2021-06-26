//
//  String+Date.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import Foundation

extension String {
    
    var toDate: Date? { Date(dateString: self) }
    
    var toTestDate: Date? { Date(rfc3339DateTimeString: self) }
    
    var toRecoveryDate: Date? { Date(dateString: self) }
    
    var toVaccineDate: Date? { Date(dateString: self) }
    
}
