/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-verifier-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//
//  Date.swift
//  DGCAVerifier
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
  static let dateTimeFormatter = formatter(for: "yyyy-MM-dd HH:mm '(UTC)'")

  var isoString: String {
    Date.isoFormatter.string(from: self)
  }
  var dateString: String {
    Date.dateFormatter.string(from: self)
  }
  var dateTimeString: String {
    Date.dateTimeFormatter.string(from: self)
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
  init?(rfc3339DateTimeString str: String) {
    let rfc3339DateTimeFormatter = DateFormatter()

    rfc3339DateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    if let date = rfc3339DateTimeFormatter.date(from: str) {
      self = date
      return
    }

    rfc3339DateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    if let date = rfc3339DateTimeFormatter.date(from: str) {
      self = date
      return
    }

    rfc3339DateTimeFormatter.dateFormat = "yyyy-MM-dd't'HH:mm:ss.SSS'z'"
    if let date = rfc3339DateTimeFormatter.date(from: str) {
      self = date
      return
    }
    return nil
  }

  var localDateString: String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.timeStyle = .none
    formatter.dateStyle = .medium
    return formatter.string(from: self)
  }
}
