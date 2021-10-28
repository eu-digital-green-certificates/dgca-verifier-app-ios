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

import UIKit
import SwiftDGC
import CertLogic

struct ViewerParts {
  static let validityIcon = [
    HCertValidity.valid: UIImage(named: "check")!,
    HCertValidity.invalid: UIImage(named: "error")!,
    HCertValidity.ruleInvalid: UIImage(named: "check")!
  ]
  static let buttonText = [
    HCertValidity.valid: l10n("btn.done"),
    HCertValidity.invalid: l10n("btn.retry"),
    HCertValidity.ruleInvalid: l10n("btn.retry")
  ]
  static let backgroundColor = [
    HCertValidity.valid: UIColor.forestGreen,
    HCertValidity.invalid: UIColor.roseRed,
    HCertValidity.ruleInvalid: UIColor.yellow
  ]
}

class CertificateViewerVC: UIViewController {
  
  private struct Constants {
    static let showSettingsController = "showSettingsController"
  }

  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var validityLabel: UILabel!
  @IBOutlet weak var validityImage: UIImageView!
  @IBOutlet weak var headerBackground: UIView!
  @IBOutlet weak var infoTable: UITableView!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var shareButton: RoundedButton!
  
  var hCert: HCert?
  private var sectionBuilder: SectionBuilder?
  private var validityState: ValidityState = .invalid
  private var debugSections = [DebugSectionModel]()
  
  // MARK: View Controller life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    infoTable.dataSource = self
    infoTable.register(UINib(nibName: "InfoCell", bundle: nil), forCellReuseIdentifier: "InfoCell")
    infoTable.register(UINib(nibName: "InfoCellDropDown", bundle: nil), forCellReuseIdentifier: "InfoCellDropDown")
    infoTable.register(UINib(nibName: "RuleErrorTVC", bundle: nil), forCellReuseIdentifier: "RuleErrorTVC")
    infoTable.register(UINib(nibName: "DebugSectionTVC", bundle: nil), forCellReuseIdentifier: "DebugSectionTVC")
    infoTable.register(UINib(nibName: "DebugRawTVC", bundle: nil), forCellReuseIdentifier: "DebugRawTVC")
    infoTable.register(UINib(nibName: "DebugValidationTVC", bundle: nil), forCellReuseIdentifier: "DebugValidationTVC")
    infoTable.register(UINib(nibName: "DebugGeneralTVC", bundle: nil), forCellReuseIdentifier: "DebugGeneralTVC")
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let hCert = hCert else { return }
    
    let validator = CertificateValidator(with: hCert)
    validityState = validator.validate()
    let builder = SectionBuilder(with: hCert, validity: validityState)
    builder.makeSections(for: .verifier)
    if let section = validityState.infoRulesSection {
      builder.makeSectionForRuleError(ruleSection: section, for: .verifier)
    }
    sectionBuilder = builder
    setupInterface()
  }

  func setupInterface() {
    guard let hCert = hCert else { return }
    
    let isDebugMode = DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert)
    shareButton.isEnabled = !isDebugMode
    shareButton.isHidden = !isDebugMode
    
    nameLabel.text = hCert.fullName
    
    let validityResult = validityState.allRulesValidity
      
    dismissButton.setTitle(ViewerParts.buttonText[validityResult], for: .normal)
    dismissButton.backgroundColor = ViewerParts.backgroundColor[validityResult]
    validityLabel.text = validityResult.l10n
    headerBackground.backgroundColor = ViewerParts.backgroundColor[validityResult]
    validityImage.image = ViewerParts.validityIcon[validityResult]
    
    debugSections.removeAll()
    debugSections.append(DebugSectionModel(hCert: hCert, sectionType: .verification))
    debugSections.append(DebugSectionModel(hCert: hCert, sectionType: .general))
    debugSections.append(DebugSectionModel(hCert: hCert, sectionType: .raw))
    
    debugSections.forEach { $0.update(hCert: hCert) }
    infoTable.reloadData()
  }
  
  // MARK: Actions
  @IBAction func settingsButtonAction() {
      self.performSegue(withIdentifier: Constants.showSettingsController, sender: nil)
  }
  
  @IBAction func dissmissButtonAction() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func shareButtonAction(_ sender: Any) {
    guard let cert = hCert else { return }
    
    ZipManager().prepareZipData(cert) { result in
      switch result {
      case .success(let url):
        var filesToShare = [Any]()
        filesToShare.append(url)
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
      case .failure(let error):
        DGCLogger.logInfo(String(format: "Error while creating zip archive: %@", error.localizedDescription))
      }
    }
  }
}

// MARK: UITableViewDataSource
extension CertificateViewerVC: UITableViewDataSource {
  var listItems: [InfoSection] {
    return sectionBuilder?.infoSection.filter {!$0.isPrivate} ?? []
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let hCert = hCert else { return 0 }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert ) {
      let debugSection = debugSections[section]
      return debugSection.numberOfItems
    }
    let infoSection: InfoSection = listItems[section]
    if infoSection.sectionItems.isEmpty {
      return 1
    } else if !infoSection.isExpanded {
      return 1
    } else {
      return infoSection.sectionItems.count + 1
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    guard let hCert = hCert else { return 0 }
    
    let isDebug = DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert)
    return isDebug ? debugSections.count : listItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let hCert = hCert else { return UITableViewCell() }
    
    if DebugManager.sharedInstance.isDebugModeFor(country: hCert.ruleCountryCode ?? "", hCert: hCert) {
      let debugSection = debugSections[indexPath.section]
      if indexPath.row == 0 {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugSectionTVC",
            for: indexPath) as? DebugSectionTVC else { return UITableViewCell() }
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugValidationTVC", for: indexPath) as?
            DebugValidationTVC else { return UITableViewCell() }
        cell.setupCell(with: validityState)
        return cell
        
      case .general:
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DebugGeneralTVC", for: indexPath) as?
            DebugGeneralTVC else { return UITableViewCell() }
        
        let reloadHandler = {
          tableView.reloadData()
        }
        cell.setupDebugSection(validity: validityState, bulder: sectionBuilder, reload: reloadHandler, needReload: true)
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
          cell.setupCell(with: infoSection) { [weak self] state in
            infoSection.isExpanded = state
            if let row = self?.sectionBuilder?.infoSection.firstIndex(where: {$0.header == infoSection.header}) {
              self?.sectionBuilder?.infoSection[row] = infoSection
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
