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
//  CertificateViewer.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import UIKit
import SwiftDGC
import CertLogic
import FloatingPanel

let dismissTimeout = 15.0

let validityIcon = [
  HCertValidity.valid: UIImage(named: "check")!,
  HCertValidity.invalid: UIImage(named: "error")!,
  HCertValidity.ruleInvalid: UIImage(named: "check")!
]
let buttonText = [
  HCertValidity.valid: l10n("btn.done"),
  HCertValidity.invalid: l10n("btn.retry"),
  HCertValidity.ruleInvalid: l10n("btn.retry")
]
let backgroundColor = [
  HCertValidity.valid: UIColor(named: "green")!,
  HCertValidity.invalid: UIColor(named: "red")!,
  HCertValidity.ruleInvalid: UIColor(named: "yellow")!
]
class CertificateViewerVC: UIViewController {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var validityLabel: UILabel!
  @IBOutlet weak var validityImage: UIImageView!
  @IBOutlet weak var headerBackground: UIView!
  @IBOutlet weak var loadingBackground: UIView!
  @IBOutlet weak var loadingBackgroundTrailing: NSLayoutConstraint!
  @IBOutlet weak var infoTable: UITableView!
  @IBOutlet weak var dismissButton: UIButton!

  var hCert: HCert?
  weak var childDismissedDelegate: CertViewerDelegate?
  var settingsOpened = false

  func draw() {
    guard let hCert = hCert else {
      return
    }

    infoTable.dataSource = self
    infoTable.register(UINib(nibName: "RuleErrorTVC", bundle: nil), forCellReuseIdentifier: "RuleErrorTVC")
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    settingsOpened = false
    loadingBackground.isUserInteractionEnabled = false
    nameLabel.text = hCert.fullName
    var validity = hCert.validity
    if validity == .valid {
      validity = validateCertLogicRules()
    }
    dismissButton.setTitle(buttonText[validity], for: .normal)
    dismissButton.backgroundColor = backgroundColor[validity]
    validityLabel.text = validity.l10n
    headerBackground.backgroundColor = backgroundColor[validity]
    validityImage.image = validityIcon[validity]
    infoTable.reloadData()
  }
    
  func validateCertLogicRules() -> HCertValidity {
    var validity: HCertValidity = .valid
    
    guard let hCert = hCert else {
      return validity
    }
    
    let certType = getCertificationType(type: hCert.type)
    if let countryCode = hCert.ruleCountryCode {
      let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
      let filterParameter = FilterParameter(validationClock: Date(),
                                            countryCode: countryCode,
                                            certificationType: certType)
      let externalParameters = ExternalParameter(validationClock: Date(),
                                                 valueSets: valueSets,
                                                 exp: hCert.exp,
                                                 iat: hCert.iat,
                                                 issuerCountryCode: hCert.issCode,
                                                 kid: hCert.kidStr)
      let result = CertLogicEngineManager.sharedInstance.validate(filter: filterParameter, external: externalParameters,
                                                                  payload: hCert.body.description)
      let failsAndOpen = result.filter { validationResult in
        return validationResult.result != .passed
      }
      if failsAndOpen.count > 0 {
        validity = .ruleInvalid
        var section = InfoSection(header: "Possible limitation", content: "Country rules validation failed")
        var listOfRulesSection: [InfoSection] = []
        result.sorted(by: { vdResultOne, vdResultTwo in
          vdResultOne.result.rawValue < vdResultTwo.result.rawValue
        }).forEach { validationResult in
          if let error = validationResult.validationErrors?.first {
            switch validationResult.result {
            case .fail:
              listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: error.localizedDescription,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
            case .open:
              listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: l10n(error.localizedDescription),
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
            case .passed:
              listOfRulesSection.append(InfoSection(header: "CirtLogic Engine error",
                                                    content: error.localizedDescription,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
            }
          } else {
            let preferredLanguage = Locale.preferredLanguages[0] as String
            let arr = preferredLanguage.components(separatedBy: "-")
            let deviceLanguage = (arr.first ?? "EN")
            var errorString = ""
            if let error = validationResult.rule?.getLocalizedErrorString(locale: deviceLanguage) {
              errorString = error
            }
            var detailsError = ""
            if let rule = validationResult.rule {
               let dict = CertLogicEngineManager.sharedInstance.getRuleDetailsError(rule: rule,
                                                                                filter: filterParameter)
              dict.keys.forEach({ key in
                    detailsError += key + ": " + (dict[key] ?? "") + " "
              })
            }
            switch validationResult.result {
            case .fail:
              listOfRulesSection.append(InfoSection(header: errorString,
                                                    content: detailsError,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.error))
            case .open:
              listOfRulesSection.append(InfoSection(header: errorString,
                                                    content: detailsError,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.open))
            case .passed:
              listOfRulesSection.append(InfoSection(header: errorString,
                                                    content: detailsError,
                                                    countryName: hCert.ruleCountryCode,
                                                    ruleValidationResult: SwiftDGC.RuleValidationResult.passed))
            }
          }
        }
        section.sectionItems = listOfRulesSection
        self.hCert?.makeSectionForRuleError(infoSections: section, for: .verifier)
        self.infoTable.reloadData()
      }
    }
    return validity
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if #available(iOS 13.0, *) {
      draw()
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.draw()
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    loadingBackgroundTrailing.priority = .init(200)
    UIView.animate(withDuration: dismissTimeout, delay: 0, options: .curveLinear) { [weak self] in
      self?.view.layoutIfNeeded()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + dismissTimeout) { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }
    if let cert = hCert {
        DebugModeManager().prepareZipData(cert) { result in
            switch result{
            case .failure(let error):
                print("Error: %@",error)
            case .success(let data):
                print(data)
            }
        }
    }
    
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    childDismissedDelegate?.childDismissed()
    if settingsOpened {
      childDismissedDelegate?.openSettings()
    }
  }

  @IBAction
  func closeButton() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction
  func settingsButton() {
    settingsOpened = true
    dismiss(animated: true, completion: nil)
  }
}

extension CertificateViewerVC: UITableViewDataSource {
  var listItems: [InfoSection] {
    hCert?.info.filter {
      !$0.isPrivate
    } ?? []
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section: InfoSection = listItems[section]
    if section.sectionItems.count == 0 {
      return 1
    }
    if !section.isExpanded {
      return 1
    }
    return section.sectionItems.count + 1
  }
  func numberOfSections(in tableView: UITableView) -> Int {
    return listItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var section: InfoSection = listItems[indexPath.section]
    if section.sectionItems.count == 0 {
      let base = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
      guard let cell = base as? InfoCell else {
        return base
      }
      cell.draw(section)
      return cell
    } else {
      if indexPath.row == 0 {
        let base = tableView.dequeueReusableCell(withIdentifier: "infoCellDropDown", for: indexPath)
        guard let cell = base as? InfoCellDropDown else {
          return base
        }
        cell.setupCell(with: section) { state in
          section.isExpanded = state
          if let row = self.hCert?.info.firstIndex(where: {$0.header == section.header}) {
            self.hCert?.info[row] = section
          }
          tableView.reloadData()
        }
        return cell
      } else {
        let base = tableView.dequeueReusableCell(withIdentifier: "RuleErrorTVC", for: indexPath)
        guard let cell = base as? RuleErrorTVC else {
          return base
        }
        let item = section.sectionItems[indexPath.row - 1]
        cell.setupCell(with: item)
        return cell

      }
    }
  }
}

// MARK: External CertType from HCert type
extension CertificateViewerVC {
  func getCertificationType(type: SwiftDGC.HCertType) -> CertificateType {
    var certType: CertificateType = .general
    switch type {
    case .recovery:
      certType = .recovery
    case .test:
      certType = .test
    case .vaccine:
      certType = .vaccination
    case .unknown:
      certType = .general
    }
    return certType
  }
}
