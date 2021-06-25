//
//  Date+Math.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import Foundation

extension Date {
    
    public var startOfDay: Date { Calendar.autoupdatingCurrent.startOfDay(for: self) }

}
