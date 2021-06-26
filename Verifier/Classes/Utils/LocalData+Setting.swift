//
//  LocalData+Setting.swift
//  VerificaC19
//
//  Created by Andrea Prosseda on 25/06/21.
//

import Foundation

extension LocalData {
    
    static func getSetting(from name: String) -> String? {
        LocalData.sharedInstance.getFirstSetting(withName: name)
    }
    
    static func getSetting(from name: String, type: String) -> String? {
        getSettings(from: name).first(where: { $0.type == type })?.value
    }
    
    static func getSettings(from key: String) -> [Setting] {
        LocalData.sharedInstance.settings.filter { $0.name == key }
    }
}
