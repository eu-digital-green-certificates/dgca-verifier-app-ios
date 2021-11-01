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
//  CertificateViewerController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import UIKit
import SwiftDGC
import CertLogic

class CertificateViewerController: UIViewController {
  
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
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  var hCert: HCert?
  private var sectionBuilder: SectionBuilder?
  private var validityState: ValidityState = .invalid
  private var debugSections = [DebugSectionModel]()
  private var isDebugMode = DebugManager.sharedInstance.isDebugMode
  
  // MARK: View Controller life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    infoTable.register(UINib(nibName: "InfoCell", bundle: nil), forCellReuseIdentifier: "InfoCell")
    infoTable.register(UINib(nibName: "InfoCellDropDown", bundle: nil), forCellReuseIdentifier: "InfoCellDropDown")
    infoTable.register(UINib(nibName: "DebugRawTVC", bundle: nil), forCellReuseIdentifier: "DebugRawTVC")
    infoTable.register(UINib(nibName: "DebugValidationTVC", bundle: nil), forCellReuseIdentifier: "DebugValidationTVC")
    infoTable.register(UINib(nibName: "DebugGeneralTVC", bundle: nil), forCellReuseIdentifier: "DebugGeneralTVC")
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    validateAndSetupInterface()
  }
  
  func validateAndSetupInterface() {
    guard let hCert = hCert else { return }
    
    activityIndicator.startAnimating()
    let validator = CertificateValidator(with: hCert)
    DispatchQueue.global(qos: .userInitiated).async {
      validator.validate {[weak self] (validityState) in
        self?.validityState = validityState
        if validityState.technicalValidity != .valid ||
            validityState.issuerInvalidation != .passed ||
            validityState.destinationAcceptence != .passed ||
            validityState.travalerAcceptence != .passed {
          
          let codes = CountryDataStorage.sharedInstance.countryCodes
          let country = hCert.ruleCountryCode ?? ""
          
          if DebugManager.sharedInstance.isDebugMode,
              let countryModel = codes.filter({ $0.code == country }).first, countryModel.debugModeEnabled {
            self?.isDebugMode = true
          } else {
            self?.isDebugMode = false
          }
        }
        
        let builder = SectionBuilder(with: hCert, validity: validityState)
        builder.makeSections(for: .verifier)
        if let section = validityState.infoRulesSection {
          builder.makeSectionForRuleError(ruleSection: section, for: .verifier)
        }
        self?.sectionBuilder = builder
        DispatchQueue.main.async {
          self?.activityIndicator.stopAnimating()
          self?.setupInterface()
        }
      }
    }
  }

  func setupInterface() {
    guard let hCert = hCert else { return }
    
    shareButton.isEnabled = !isDebugMode
    shareButton.isHidden = !isDebugMode
    
    nameLabel.text = hCert.fullName
    let validity = validityState.allRulesValidity
      
    dismissButton.setTitle(validity.validityButtonTitle, for: .normal)
    dismissButton.backgroundColor = validity.validityBackground
    validityLabel.text = validity.validityResult
    headerBackground.backgroundColor = validity.validityBackground
    validityImage.image = validity.validityImage
    
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
  
  // MARK: Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showSettingsController:
      if let destinationController = segue.destination as? UINavigationController,
         let rootController = destinationController.viewControllers.first as? SettingsTableVC {
        rootController.delegate = self
      }
    default:
      break
    }
  }
}

// MARK: UITableViewDataSource
extension CertificateViewerController: UITableViewDataSource {
  var listItems: [InfoSection] {
    return sectionBuilder?.infoSection.filter {!$0.isPrivate} ?? []
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isDebugMode {
      let debugSection = debugSections[section]
      return debugSection.numberOfItems
    } else {
      let infoSection: InfoSection = listItems[section]
      if infoSection.sectionItems.isEmpty {
        return 1
      } else if !infoSection.isExpanded {
        return 1
      } else {
        return infoSection.sectionItems.count + 1
      }
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return isDebugMode ? debugSections.count : listItems.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isDebugMode {
      let debugSection = debugSections[indexPath.section]
      if indexPath.row == 0 {
        let cellID = String(describing: DebugSectionCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugSectionCell else {
          return UITableViewCell()
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
        let cellID = String(describing: DebugRawTVC.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugRawTVC else {
          return UITableViewCell()
        }
        
        cell.setDebugSection(debugSection: debugSection)
        return cell
        
      case .verification:
        let cellID = String(describing: DebugValidationTVC.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugValidationTVC else {
          return UITableViewCell()
        }
        cell.setupCell(with: validityState)
        return cell
        
      case .general:
        let cellID = String(describing: DebugGeneralTVC.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugGeneralTVC else {
          return UITableViewCell()
        }
        
        let reloadHandler = {
          tableView.reloadData()
        }
        cell.setupDebugSection(validity: validityState, bulder: sectionBuilder, reload: reloadHandler, needReload: true)
        return cell
      }
      
    } else {
      let infoSection = listItems[indexPath.section]
      if infoSection.sectionItems.count == 0 {
        let cellID = String(describing: InfoCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? InfoCell else {
          return UITableViewCell()
        }
        cell.setupCell(with: infoSection)
        return cell
        
      } else {
        if indexPath.row == 0 {
          let cellID = String(describing: InfoCellDropDown.self)
          guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? InfoCellDropDown else {
            return UITableViewCell()
          }
          cell.setupCell(with: infoSection) { [weak self] state in
            infoSection.isExpanded = state
            if let row = self?.sectionBuilder?.infoSection.firstIndex(where: {$0.header == infoSection.header}) {
              self?.sectionBuilder?.infoSection[row] = infoSection
            }
            tableView.reloadData()
          }
          return cell
          
        } else {
          let cellID = String(describing: RuleErrorCell.self)
          guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? RuleErrorCell else {
            return UITableViewCell()
          }
          let item = infoSection.sectionItems[indexPath.row - 1]
          cell.setupCell(with: item)
          return cell
        }
      }
    }
  }
}

extension CertificateViewerController: DebugControllerDelegate {
  func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
    validateAndSetupInterface()
  }
}
