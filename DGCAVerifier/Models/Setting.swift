//
//  MedicalRule.swift
//  Verifier
//
//  Created by Davide Aliti on 20/05/21.
//

import Foundation

struct Setting: Codable {
    var name: String
    var type: String
    var value: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case value
    }
}
