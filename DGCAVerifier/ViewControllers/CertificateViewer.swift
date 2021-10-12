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
  
  // MARK: View Controller life cycle
  override func viewDidLoad() {
      super.viewDidLoad()
        
      setupInterface()
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

  func setupInterface() {
    guard let hCert = hCert else { return }
    
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

  // MARK: validate
  func validateCertLogicForAllRules() -> HCertValidity {
    var validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
    
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
      let result = CertLogicEngineManager.sharedInstance.validate(filter: filterParameter, external: externalParameters, payload: hCert.body.description)
      let failsAndOpen = result.filter { $0.result != .passed }
      
      if failsAndOpen.count > 0 {
        validity = .ruleInvalid
        var section = InfoSection(header: "Possible limitation", content: "Country rules validation failed")
        var listOfRulesSection: [InfoSection] = []
        result.sorted(by: { $0.result.rawValue < $1.result.rawValue }).forEach { validationResult in
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
        debugSections.forEach { $0.update(hCert: hCert) }
        self.infoTable.reloadData()
      }
    }
    return validity
  }
  
  func validateCertLogicForIssuer() -> HCertValidity {
    let validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
    
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
      let result = CertLogicEngineManager.sharedInstance.validateIssuer(filter: filterParameter,
          external: externalParameters, payload: hCert.body.description)
      let fails = result.filter { $0.result == .fail }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { $0.result == .open }
      if !open.isEmpty {
        return .ruleInvalid
      }
    }
    return validity
  }

  func validateCertLogicForDestination() -> HCertValidity {
    let validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
    
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
      let result = CertLogicEngineManager.sharedInstance.validateDestination(filter: filterParameter, external: externalParameters, payload: hCert.body.description)
      let fails = result.filter { $0.result == .fail }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { $0.result == .open }
      if !open.isEmpty {
        return .ruleInvalid
      }
    }
    return validity
  }
  
  func validateCertLogicForTraveller() -> HCertValidity {
    let validity: HCertValidity = .valid
    guard let hCert = hCert else { return validity }
    
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
      let result = CertLogicEngineManager.sharedInstance.validateTraveller(filter: filterParameter, external: externalParameters, payload: hCert.body.description)
      
      let fails = result.filter { $0.result == .fail }
      if !fails.isEmpty {
        return .invalid
      }
      let open = result.filter { $0.result == .open }
      if !open.isEmpty {
        return .ruleInvalid
      }
    }
    return validity
  }

  // MARK: Actions
  @IBAction func closeButton() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func settingsButton() {
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

// MARK: UITableViewDataSource
extension CertificateViewerVC: UITableViewDataSource {
  var listItems: [InfoSection] {
    return hCert?.info.filter {!$0.isPrivate} ?? []
  }

  // Number of rows
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let hCert = hCert else { return 0 }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert ) {
      let debugSection = debugSections[section]
      return debugSection.numberOfItems
    }
    let section: InfoSection = listItems[section]
    if section.sectionItems.isEmpty {
      return 1
    } else if !section.isExpanded {
      return 1
    } else {
      return section.sectionItems.count + 1
    }
  }
  // Number of Sections
  func numberOfSections(in tableView: UITableView) -> Int {
    guard let hCert = hCert else { return 0 }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      return debugSections.count
    } else {
      return listItems.count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let hCert = hCert else { return UITableViewCell() }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      let debugSection = debugSections[indexPath.section]
      if indexPath.row == 0 {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugSectionTVC", for: indexPath) as? DebugSectionTVC else { return UITableViewCell() }
        
        cell.setDebugSection(debugSection: debugSection)
        cell.expandCallback = { debugSectionFromCB in
          debugSection.isExpanded = debugSectionFromCB?.isExpanded ?? false
          tableView.reloadData()
        }
        return cell
      }
      
      switch debugSection.sectionType {
      case .raw:
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugRawTVC", for: indexPath) as?
            DebugRawTVC else { return UITableViewCell() }
        
          cell.setDebugSection(debugSection: debugSection)
          return cell
        
      case .verification:
        guard let cell  = tableView.dequeueReusableCell(withIdentifier: "DebugValidationTVC", for: indexPath) as?
            DebugValidationTVC else { return UITableViewCell() }
        
        cell.setDebugSection(debugSection: debugSection)
        return cell
        
      case .general:
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugGeneralTVC", for: indexPath) as?
            DebugGeneralTVC else { return UITableViewCell() }
        
        cell.reload = {
          tableView.reloadData()
        }
        cell.setDebugSection(debugSection: debugSection, needReload: self.needReload)
        return cell
      }
    } else {
      var infoSection: InfoSection = listItems[indexPath.section]
      if infoSection.sectionItems.count == 0 {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell",
            for: indexPath) as? InfoCell else { return UITableViewCell() }

        cell.setupCell(with: infoSection)
        return cell
      } else {
        if indexPath.row == 0 {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCellDropDown", for: indexPath) as?
              InfoCellDropDown else { return UITableViewCell() }
          
          cell.setupCell(with: infoSection) { state in
            infoSection.isExpanded = state
            if let row = self.hCert?.info.firstIndex(where: {$0.header == infoSection.header}) {
              self.hCert?.info[row] = infoSection
            }
            tableView.reloadData()
          }
          return cell
          
        } else {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: "RuleErrorTVC", for: indexPath) as?
              RuleErrorTVC else { return UITableViewCell() }
          
          let item = infoSection.sectionItems[indexPath.row - 1]
          cell.setupCell(with: item)
          return cell
        }
      }
    }
  }
}

// MARK: External CertType from HCert type
extension CertificateViewerVC {
  func getCertificationType(type: SwiftDGC.HCertType) -> CertificateType {
    switch type {
    case .recovery:
      return .recovery
    case .test:
      return .test
    case .vaccine:
      return .vaccination
    case .unknown:
      return .general
    }
  }
}
