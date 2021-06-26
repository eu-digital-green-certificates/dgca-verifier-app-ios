//
//  DateFormatter+Default.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 26/06/21.
//

import Foundation

extension DateFormatter {
    
    static func getDefault(utc: Bool = true) -> DateFormatter {
        let df = DateFormatter()
        guard utc else { return df }
        df.timeZone = TimeZone(abbreviation: "UTC")
        return df
    }
}
