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
//  RuleErrorCell.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 05.07.2021.
//  

import UIKit
import DGCCoreLibrary

class RuleErrorCell: UITableViewCell {
  @IBOutlet fileprivate weak var ruleLabel: UILabel!
  @IBOutlet fileprivate weak var ruleValueLabel: UILabel!
  @IBOutlet fileprivate weak var currentLabel: UILabel!
  @IBOutlet fileprivate weak var currentValueLabel: UILabel!
  @IBOutlet fileprivate weak var resultLabel: UILabel!
  @IBOutlet fileprivate weak var resultValueLabel: UILabel!
  @IBOutlet fileprivate weak var failedLabel: UILabel!
  
  private var infoItem: InfoSection? {
    didSet {
      setupView()
    }
  }

  func setupCell(with info: InfoSection) {
    self.infoItem = info
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    infoItem = nil
  }

  // MARK: Private methods
  private func setupLabels() {
    ruleLabel.text = "Rule".localized
    ruleValueLabel.text = ""
    currentLabel.text = "Current".localized
    currentValueLabel.text = ""
    resultLabel.text = "Result".localized
    resultValueLabel.text = ""
  }

  private func setupView() {
    guard let infoItem = infoItem else { setupLabels(); return }
    
    ruleValueLabel.text = infoItem.header
    currentValueLabel.text = infoItem.content
    switch infoItem.ruleValidationResult {
    case .invalid:
      failedLabel.textColor = .certificateRed
      failedLabel.text = "Failed".localized
    case .valid:
      failedLabel.textColor = .certificateGreen
      failedLabel.text = "Passed".localized
    case .partlyValid:
      failedLabel.textColor = .certificateGreen
      failedLabel.text = "Open".localized
    }

    if let countryName = infoItem.countryName {
      switch infoItem.ruleValidationResult {
      case .invalid:
        resultValueLabel.text = String(format: "Failed for %@ (see settings)".localized, countryName)
      case .valid:
        resultValueLabel.text = String(format: "Passed for %@ (see settings)".localized, countryName)
      case .partlyValid:
        resultValueLabel.text = String(format: "Open for %@ (see settings)".localized, countryName)
      }
      
    } else {
      switch infoItem.ruleValidationResult {
      case .invalid:
        resultValueLabel.text = "Failed".localized
      case .valid:
        resultValueLabel.text = "Passed".localized
      case .partlyValid:
        resultValueLabel.text = "Open".localized
      }
    }
  }
}
