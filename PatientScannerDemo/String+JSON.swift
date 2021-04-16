//
//  File.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/13/21.
//

import Foundation

extension String {
  var asJSONDict: [String: AnyObject] {
    if let data = data(using: .utf8) {
      do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
        return json ?? [:]
      } catch {
        return [:]
      }
    }
    return [:]
  }
}
