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
  static let dateFormatter = formatter(for: "yyyy-MM-dd")

  var isoString: String {
    Date.isoFormatter.string(from: self)
  }
  var dateString: String {
    Date.dateFormatter.string(from: self)
  }

  init?(isoString: String) {
    guard let date = Date.isoFormatter.date(from: isoString) else {
      return nil
    }
    self = date
  }
  init?(dateString: String) {
    guard let date = Date.dateFormatter.date(from: dateString) else {
      return nil
    }
    self = date
  }
}
