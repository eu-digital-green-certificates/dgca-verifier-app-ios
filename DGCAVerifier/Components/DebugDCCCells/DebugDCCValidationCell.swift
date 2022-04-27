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
//  DebugDCCValidationCell.swift
//  DGCAVerifier
//
//  Created by Alexandr Chernyy on 07.09.2021.
//
        

import UIKit
import DGCCoreLibrary

enum Icons: String {
  case ok = "\u{f00c}"
  case limited = "\u{f128}"
  case error = "\u{f05e}"
}

class DebugDCCValidationCell: UITableViewCell {

  @IBOutlet weak var techninalLabel: UILabel!
  @IBOutlet weak var issuerLabel: UILabel!
  @IBOutlet weak var destinationLabel: UILabel!
  @IBOutlet weak var travellerLabel: UILabel!
  @IBOutlet weak var technivalView: UILabel!
  @IBOutlet weak var issuerView: UILabel!
  @IBOutlet weak var destinationView: UILabel!
  @IBOutlet weak var travvelerView: UILabel!
  
  private var validityState: ValidityState?
      
  func setupCell(with validity: ValidityState?) {
    self.validityState = validity
    setupView()
    setupIcons()
    setupColors()
    techninalLabel.text = "Technical Verification".localized
    issuerLabel.text = "Issuer Invalidation".localized
    destinationLabel.text = "Destination Acceptance".localized
    travellerLabel.text = "Traveller Acceptance".localized
  }
  
  private func setupView() {
    technivalView.layer.cornerRadius = 15
    technivalView.layer.masksToBounds = true
    issuerView.layer.cornerRadius = 15
    issuerView.layer.masksToBounds = true
    destinationView.layer.cornerRadius = 15
    destinationView.layer.masksToBounds = true
    travvelerView.layer.cornerRadius = 15
    travvelerView.layer.masksToBounds = true
    technivalView.layer.borderWidth = 1
    issuerView.layer.borderWidth = 1
    destinationView.layer.borderWidth = 1
    travvelerView.layer.borderWidth = 1
    technivalView.layer.borderColor = UIColor.brown.cgColor
    issuerView.layer.borderColor = UIColor.brown.cgColor
    destinationView.layer.borderColor = UIColor.brown.cgColor
    travvelerView.layer.borderColor = UIColor.brown.cgColor
  }
  
  private func setupIcons() {
    technivalView.text = validityState?.technicalValidityString
    issuerView.text = validityState?.issuerInvalidationString
    destinationView.text = validityState?.destinationAcceptenceString
    travvelerView.text = validityState?.travalerAcceptenceString
  }
  
  private func setupColors() {
    technivalView.backgroundColor = validityState?.technicalValidityColor ?? .red
    issuerView.backgroundColor = validityState?.issuerInvalidationColor ?? .red
    destinationView.backgroundColor = validityState?.destinationAcceptenceColor ?? .red
    travvelerView.backgroundColor = validityState?.travalerAcceptenceColor ?? .red
  }
}
