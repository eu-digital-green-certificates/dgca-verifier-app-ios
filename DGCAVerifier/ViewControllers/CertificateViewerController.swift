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

protocol DismissControllerDelegate: AnyObject {
  func userDidDissmiss(_ controller: UIViewController) //DismissControllerDelegate
}

protocol CertificateSectionsProtocol {}
extension InfoSection: CertificateSectionsProtocol {}
extension DebugSectionModel: CertificateSectionsProtocol {}

class CertificateViewerController: UIViewController {
  private struct Constants {
    static let showSettingsController = "showSettingsController"
  }

  @IBOutlet fileprivate weak var nameLabel: UILabel!
  @IBOutlet fileprivate weak var validityLabel: UILabel!
  @IBOutlet fileprivate weak var validityImage: UIImageView!
  @IBOutlet fileprivate weak var headerBackground: UIView!
  @IBOutlet fileprivate weak var infoTable: UITableView!
  @IBOutlet fileprivate weak var dismissButton: RoundedButton!
  @IBOutlet fileprivate weak var shareButton: RoundedButton!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

  var hCert: HCert?
  weak var dismissDelegate: DismissControllerDelegate?
  
  private var sectionBuilder: SectionBuilder?
  private var validityState: ValidityState = .invalid
  private var isDebugMode = DebugManager.sharedInstance.isDebugMode
  
  private var listItems: [InfoSection] {
    sectionBuilder?.infoSection.filter { !$0.isPrivate } ?? []
  }
  private var debugSections = [DebugSectionModel]()
  private var certificateSections: [CertificateSectionsProtocol] = []


  // MARK: View Controller life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    validateAndSetupInterface()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      if (isBeingDismissed || isMovingFromParent) {
        dismissDelegate?.userDidDissmiss(self)
      }
  }
  private func validateAndSetupInterface() {
    guard let hCert = hCert else { return }
    
    isDebugMode = DebugManager.sharedInstance.isDebugMode
    activityIndicator.startAnimating()
    dismissButton.setTitle("Cancel".localized, for: .normal)
    dismissButton.backgroundColor = UIColor.certificateLimited
    
    let validator = CertificateValidator(with: hCert)
    DispatchQueue.global(qos: .userInitiated).async {
      validator.validate {[weak self] (validityState) in
        self?.validityState = validityState
        if validityState.technicalValidity != .valid ||
            validityState.issuerInvalidation != .passed ||
            validityState.destinationAcceptence != .passed ||
            validityState.travalerAcceptence != .passed {
          
          let codes = DataCenter.countryCodes
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

  private func setupInterface() {
    guard let hCert = hCert else { return }
      
    shareButton.setTitle("Share".localized, for: .normal)
    nameLabel.text = hCert.fullName
    let validity = validityState.allRulesValidity
    
    dismissButton.setTitle(validity.validityButtonTitle, for: .normal)
    dismissButton.backgroundColor = validity.validityBackground
    validityLabel.text = validity.validityResult
    headerBackground.backgroundColor = validity.validityBackground
    validityImage.image = validity.validityImage
    
    if isDebugMode && (validity != .valid) {
      debugSections.removeAll()
      debugSections.append(DebugSectionModel(sectionType: .verification))
      debugSections.append(DebugSectionModel(sectionType: .raw))
      certificateSections = debugSections + listItems
      shareButton.isHidden = false

    } else {
      certificateSections = listItems
      shareButton.isHidden = true
    }
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
         let rootController = destinationController.viewControllers.first as? SettingsController {
        rootController.delegate = self
      }
    default:
      break
    }
  }
}

// MARK: UITableViewDataSource
extension CertificateViewerController: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return certificateSections.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      let debugSection = certificateSections[section]
    
      switch debugSection.self {
      case is DebugSectionModel:
        return (debugSection as! DebugSectionModel).numberOfItems
        
      case is InfoSection:
        let infoSection = debugSection as! InfoSection
        if infoSection.sectionItems.isEmpty {
          return 1
        } else if !infoSection.isExpanded {
          return 1
        } else {
          return infoSection.sectionItems.count + 1
        }
      default:
        return 0
      }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let certDebugSection = certificateSections[indexPath.section]
            
      switch certDebugSection.self {
      case is DebugSectionModel:
        let debugSection = certDebugSection as! DebugSectionModel
        
        if indexPath.row == 0 {
          let cellID = String(describing: DebugSectionCell.self)
          guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugSectionCell else {
            return UITableViewCell()
          }
          cell.setupCell(for: debugSection)
          cell.expandCallback = { debugSectionFromCB in
            debugSection.isExpanded = debugSectionFromCB?.isExpanded ?? false
            tableView.reloadData()
          }
          return cell
          
        } else {
          switch debugSection.sectionType {
          case .raw:
            let cellID = String(describing: DebugRawCell.self)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugRawCell else {
              return UITableViewCell()
            }
            cell.setupCell(for: debugSection, cert: hCert)
            cell.delegate = self
            return cell
            
          case .verification:
            let cellID = String(describing: DebugValidationCell.self)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugValidationCell else {
              return UITableViewCell()
            }
            cell.setupCell(with: validityState)
            return cell
        }
      }
      
      case is InfoSection:
        let infoSection: InfoSection = certificateSections[indexPath.section] as! InfoSection

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

      default:
        return UITableViewCell()
      }
    }
}

extension CertificateViewerController: DebugRawSharing {
   func userDidShare(text: String) {
    let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    self.present(activityViewController, animated: true, completion: nil)
  }
}
                                        
extension CertificateViewerController: DebugControllerDelegate {
  func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
    validateAndSetupInterface()
  }
}
