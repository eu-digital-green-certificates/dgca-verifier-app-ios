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
//  DebugValidationTVC.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 07.09.2021.
//  
        

import UIKit

enum Icons: String {
  case ok = "\u{f00c}"
  case limited = "\u{f128}"
  case error = "\u{f05e}"
}

let valid = UIColor(red: 183.0/255.0, green: 190.0/255.0, blue: 77.0/255.0, alpha: 1.0)
let invalid = UIColor(red: 207.0/255.0, green: 28.0/255.0, blue: 4.0/255.0, alpha: 1.0)
let open = UIColor(red: 237.0/255.0, green: 210.0/255.0, blue: 65.0/255.0, alpha: 1.0)

class DebugValidationTVC: UITableViewCell {

  @IBOutlet weak var techninalLabel: UILabel!
  @IBOutlet weak var issuerLabel: UILabel!
  @IBOutlet weak var destinationLabel: UILabel!
  @IBOutlet weak var travellerLabel: UILabel!
  
  @IBOutlet weak var technivalView: UILabel!
  @IBOutlet weak var issuerView: UILabel!
  @IBOutlet weak var destinationView: UILabel!
  @IBOutlet weak var travvelerView: UILabel!
  
  private var debugSection: DebugSectionModel? {
    didSet {
      setupView()
    }
  }
  var validator: CertificateValidator?
      
  func setupDebugSection(debugSection: DebugSectionModel) {
    self.debugSection = debugSection
  }
  
  func setupView() {
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
    
    setupIcons()
    setupColors()
  }
  
  private func setupIcons() {
    guard let validator = validator else { return }
    switch validator.technicalVerification {
      case .valid:
        technivalView.text = Icons.ok.rawValue
      case .invalid:
        technivalView.text = Icons.error.rawValue
      case .ruleInvalid:
        technivalView.text = Icons.limited.rawValue
    }

    switch validator.issuerInvalidation {
      case .passed:
        issuerView.text = Icons.ok.rawValue
      case .error:
        issuerView.text = Icons.error.rawValue
      case .open:
        issuerView.text = Icons.limited.rawValue
    }

    switch validator.destinationAcceptence {
    case .passed:
      destinationView.text = Icons.ok.rawValue
    case .error:
      destinationView.text = Icons.error.rawValue
    case .open:
      destinationView.text = Icons.limited.rawValue
    }

    switch validator.travalerAcceptence {
    case .passed:
      travvelerView.text = Icons.ok.rawValue
    case .error:
      travvelerView.text = Icons.error.rawValue
    case .open:
      travvelerView.text = Icons.limited.rawValue
    }
  }
  
  private func setupColors() {
      guard let validator = validator else { return }

    switch validator.technicalVerification {
      case .valid:
        technivalView.backgroundColor = valid
      case .invalid:
        technivalView.backgroundColor = invalid
      case .ruleInvalid:
        technivalView.backgroundColor = open
    }

    switch validator.issuerInvalidation {
      case .passed:
        issuerView.backgroundColor = valid
      case .error:
        issuerView.backgroundColor = invalid
      case .open:
        issuerView.backgroundColor = open
    }

    switch validator.destinationAcceptence {
    case .passed:
      destinationView.backgroundColor = valid
    case .error:
      destinationView.backgroundColor = invalid
    case .open:
      destinationView.backgroundColor = open
    }

    switch validator.travalerAcceptence {
    case .passed:
      travvelerView.backgroundColor = valid
    case .error:
      travvelerView.backgroundColor = invalid
    case .open:
      travvelerView.backgroundColor = open
    }
  }
}
