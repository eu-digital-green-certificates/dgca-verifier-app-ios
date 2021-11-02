//
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
//  DebugRawCell.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit
import SwiftDGC

class DebugRawCell: UITableViewCell {
  @IBOutlet fileprivate weak var rawLabel: UILabel!

  func setupCell(for _: DebugSectionModel, cert: HCert?) {
      self.cert = cert
  }

  private var cert: HCert? {
    didSet {
      setupView()
    }
  }
  
  private func setupView() {
    guard let cert = cert else {
      rawLabel.text = ""
      return
    }
    rawLabel.text = cert.body.description
    rawLabel.sizeToFit()
  }
}
