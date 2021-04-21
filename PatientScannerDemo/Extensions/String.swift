//
//  String.swift
//  PatientScannerDemo
//
//  Created by Yannick Spreen on 4/21/21.
//

import Foundation

extension String {
  subscript(i: Int) -> String {
    return String(self[index(startIndex, offsetBy: i)])
  }
}
