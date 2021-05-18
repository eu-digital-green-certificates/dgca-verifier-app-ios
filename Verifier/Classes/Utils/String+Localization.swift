//
//  String+localization.swift
//  verifier-ios
//
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: .main, value: "", comment: "")
    }
}
