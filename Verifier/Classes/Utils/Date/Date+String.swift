//
//  Date+String.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 26/06/21.
//

import Foundation

extension Date {
    
    var toDateString: String {
        let df = DateFormatter.getDefault(utc: false)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: self)
    }
    
    var toDateTimeString: String {
        let df = DateFormatter.getDefault(utc: true)
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
        return df.string(from: self)
    }
    
}
