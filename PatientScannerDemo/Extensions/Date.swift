//
//  Date.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation

extension Date {
  static func formatter(for locale: String, utcPosix: Bool = true, utc: Bool = false) -> DateFormatter {
    let dateTimeFormatter = DateFormatter()
    dateTimeFormatter.dateFormat = locale
    dateTimeFormatter.timeZone = TimeZone.current
    dateTimeFormatter.locale = Locale.current
    if utcPosix || utc {
      dateTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    if utcPosix {
      dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
    }
    return dateTimeFormatter
  }

  static let isoFormatter = formatter(for: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")

  var isoString: String {
    Date.isoFormatter.string(from: self)
  }
}
