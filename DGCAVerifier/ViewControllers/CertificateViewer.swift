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
import OSLog

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
  @IBOutlet weak var shareButton: RoundedButton!
  
  var hCert: HCert?
  weak var childDismissedDelegate: CertViewerDelegate?
  var settingsOpened = false
  private var debugSections = [DebugSectionModel]()
  private var needReload: Bool = true
  
  func draw() {
    guard let hCert = hCert else {
      return
    }
    
    if !DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      shareButton.isEnabled = false
      shareButton.isHidden = true
    } else {
      shareButton.isEnabled = true
      shareButton.isHidden = false
    }

    infoTable.dataSource = self
    infoTable.register(UINib(nibName: "InfoCell", bundle: nil), forCellReuseIdentifier: "InfoCell")
    infoTable.register(UINib(nibName: "InfoCellDropDown", bundle: nil), forCellReuseIdentifier: "InfoCellDropDown")
    infoTable.register(UINib(nibName: "RuleErrorTVC", bundle: nil), forCellReuseIdentifier: "RuleErrorTVC")
    infoTable.register(UINib(nibName: "DebugSectionTVC", bundle: nil), forCellReuseIdentifier: "DebugSectionTVC")
    infoTable.register(UINib(nibName: "DebugRawTVC", bundle: nil), forCellReuseIdentifier: "DebugRawTVC")
    infoTable.register(UINib(nibName: "DebugValidationTVC", bundle: nil), forCellReuseIdentifier: "DebugValidationTVC")
    infoTable.register(UINib(nibName: "DebugGeneralTVC", bundle: nil), forCellReuseIdentifier: "DebugGeneralTVC")
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    settingsOpened = false
    loadingBackground.isUserInteractionEnabled = false
    nameLabel.text = hCert.fullName
    var validity = hCert.validity
    self.hCert?.technicalVerification = validity
    
    var validResutl = validateCertLogicForIssuer()
    switch validResutl {
      case .valid:
        self.hCert?.issuerInvalidation = .passed
      case .invalid:
        self.hCert?.issuerInvalidation = .error
      case .ruleInvalid:
        self.hCert?.issuerInvalidation = .open
    }

    validResutl = validateCertLogicForDestination()
    switch validResutl {
      case .valid:
        self.hCert?.destinationAcceptence = .passed
      case .invalid:
        self.hCert?.destinationAcceptence = .error
      case .ruleInvalid:
        self.hCert?.destinationAcceptence = .open
    }

    validResutl = validateCertLogicForTraveller()
    switch validResutl {
      case .valid:
        self.hCert?.travalerAcceptence = .passed
      case .invalid:
        self.hCert?.travalerAcceptence = .error
      case .ruleInvalid:
        self.hCert?.travalerAcceptence = .open
    }
    if validity == .valid {
      validity = validateCertLogicForAllRules()
    }
    dismissButton.setTitle(buttonText[validity], for: .normal)
    dismissButton.backgroundColor = backgroundColor[validity]
    validityLabel.text = validity.l10n
    headerBackground.backgroundColor = backgroundColor[validity]
    validityImage.image = validityIcon[validity]
    debugSections.append(DebugSectionModel(hCert: self.hCert ?? hCert, sectionType: .verification))
    debugSections.append(DebugSectionModel(hCert: self.hCert ?? hCert, sectionType: .general))
    debugSections.append(DebugSectionModel(hCert: self.hCert ?? hCert, sectionType: .raw))
    infoTable.reloadData()
  }

  func validateCertLogicForAllRules() -> HCertValidity {
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
        debugSections.forEach { section in
          section.update(hCert: self.hCert!)
        }
        self.infoTable.reloadData()
      }
    }
    return validity
  }
  
  func validateCertLogicForIssuer() -> HCertValidity {
    let validity: HCertValidity = .valid
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
      let result = CertLogicEngineManager.sharedInstance.validateIssuer(filter: filterParameter, external: externalParameters,
                                                                  payload: hCert.body.description)
      let fails = result.filter { validationResult in
        return validationResult.result == .fail
      }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { validationResult in
        return validationResult.result == .open
      }
      if !open.isEmpty {
        return .ruleInvalid
      }
    }
    return validity
  }

  func validateCertLogicForDestination() -> HCertValidity {
    let validity: HCertValidity = .valid
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
      let result = CertLogicEngineManager.sharedInstance.validateDestination(filter: filterParameter, external: externalParameters,
                                                                  payload: hCert.body.description)
      let fails = result.filter { validationResult in
        return validationResult.result == .fail
      }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { validationResult in
        return validationResult.result == .open
      }
      if !open.isEmpty {
        return .ruleInvalid
      }
    }
    return validity
  }
  
  func validateCertLogicForTraveller() -> HCertValidity {
    let validity: HCertValidity = .valid
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
      let result = CertLogicEngineManager.sharedInstance.validateTraveller(filter: filterParameter, external: externalParameters,
                                                                  payload: hCert.body.description)
      let fails = result.filter { validationResult in
        return validationResult.result == .fail
      }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { validationResult in
        return validationResult.result == .open
      }
      if !open.isEmpty {
        return .ruleInvalid
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
  @IBAction func shareButtonAction(_ sender: Any) {
    guard let cert = hCert else {
      return
    }
    ZipManager().prepareZipData(cert) { result in
      switch result {
      case .success(let url):
        var filesToShare = [Any]()
        filesToShare.append(url)
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

        self.present(activityViewController, animated: true, completion: nil)
      case .failure(let error):
        os_log("Error while creating zip archive: %@", log: .default, type: .error, String(describing: error))
      }
      
    }
    
  }
  
  
}

extension CertificateViewerVC: UITableViewDataSource {
  var listItems: [InfoSection] {
    hCert?.info.filter {
      !$0.isPrivate
    } ?? []
  }

  // Number of rows
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let hCert = hCert else {
      return 0
    }
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert ) {
      let debugSection = debugSections[section]
      return debugSection.numberOfItems
    }
    let section: InfoSection = listItems[section]
    if section.sectionItems.count == 0 {
      return 1
    }
    if !section.isExpanded {
      return 1
    }
    return section.sectionItems.count + 1
  }
  // Number of Sections
  func numberOfSections(in tableView: UITableView) -> Int {
    guard let hCert = hCert else {
      return 0
    }
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      return debugSections.count
    }
    return listItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let hCert = hCert else {
      return UITableViewCell()
    }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      let debugSection = debugSections[indexPath.section]
      if indexPath.row == 0 {
        let base = tableView.dequeueReusableCell(withIdentifier: "DebugSectionTVC", for: indexPath)
        guard let cell = base as? DebugSectionTVC else {
          return base
        }
        cell.setDebugSection(debugSection: debugSection)
        cell.expandCallback = { debugSectionFromCB in
          debugSection.isExpanded = debugSectionFromCB?.isExpanded ?? false
          tableView.reloadData()
        }
        return cell
      }
      switch debugSection.sectionType {
      case .raw:
          let base = tableView.dequeueReusableCell(withIdentifier: "DebugRawTVC", for: indexPath)
          guard let cell = base as? DebugRawTVC else {
            return base
          }
          cell.setDebugSection(debugSection: debugSection)
          return cell
      case .verification:
        let base = tableView.dequeueReusableCell(withIdentifier: "DebugValidationTVC", for: indexPath)
        guard let cell = base as? DebugValidationTVC else {
          return base
        }
        cell.setDebugSection(debugSection: debugSection)
        return cell
      case .general:
        let base = tableView.dequeueReusableCell(withIdentifier: "DebugGeneralTVC", for: indexPath)
        guard let cell = base as? DebugGeneralTVC else {
          return base
        }
        cell.reload = {
          tableView.reloadData()
        }
        cell.setDebugSection(debugSection: debugSection, needReload: self.needReload)
        return cell
      }
    }
    
    var section: InfoSection = listItems[indexPath.section]
    if section.sectionItems.count == 0 {
      let base = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
      guard let cell = base as? InfoCell else {
        return base
      }
      cell.draw(section)
      return cell
    } else {
      if indexPath.row == 0 {
        let base = tableView.dequeueReusableCell(withIdentifier: "InfoCellDropDown", for: indexPath)
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
