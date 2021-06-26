//
//  Date+Math.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import Foundation

extension Date {
    
    static var startOfDay: Date? { Date().toDateString.toDate }
        
    func add(_ value: Int, ofType type: Calendar.Component) -> Date? {
        Calendar.current.date(byAdding: type, value: value, to: self)
    }
    
    func sub(_ value: Int, ofType type: Calendar.Component) -> Date? {
        Calendar.current.date(byAdding: type, value: -value, to: self)
    }
    
}
