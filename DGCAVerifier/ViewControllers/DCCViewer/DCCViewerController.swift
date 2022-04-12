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
//  DCCViewerController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import UIKit
import DGCVerificationCenter
import DCCInspection
import DGCCoreLibrary

protocol CertificateSectionsProtocol {}
extension InfoSection: CertificateSectionsProtocol {}
extension DebugSectionModel: CertificateSectionsProtocol {}

class DCCViewerController: UIViewController {
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
    
    var certificate: MultiTypeCertificate?
    weak var dismissDelegate: DismissControllerDelegate?
    
    private var sectionBuilder: DCCSectionBuilder?
    private var validityState: ValidityState?
    let verificationCenter = AppManager.shared.verificationCenter

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
        validateCertificate()
    }
    
    private func validateCertificate() {
        self.checkCertificateValidity()
        self.setupInterface()
    }
    
    private func checkCertificateValidity() {
        guard let cert = certificate?.digitalCertificate as? HCert else { return }
        
        isDebugMode = DebugManager.sharedInstance.isDebugMode
        
        let validityState = AppManager.shared.verificationCenter.dccInspector?.validateCertificate(cert)
        
        if let state = validityState as? ValidityState {
            if state.isVerificationFailed {
                let codes = DCCDataCenter.countryCodes
                let country = cert.ruleCountryCode ?? ""
                
                if DebugManager.sharedInstance.isDebugMode,
                    let countryModel = codes.filter({ $0.code == country }).first, countryModel.debugModeEnabled {
                    self.isDebugMode = true
                } else {
                    self.isDebugMode = false
                }
            }
            self.sectionBuilder = DCCSectionBuilder(with: cert, validity: state, for: .verifier)
            self.validityState = state
        }
    }
    
    private func setupInterface() {
        guard let certificate = certificate else { return }
        
        shareButton.setTitle("Share".localized, for: .normal)
        nameLabel.text = certificate.fullName
        if let _ = validityState?.isRevoked {
            dismissButton.setTitle("Retry".localized, for: .normal)
            dismissButton.backgroundColor = validityState?.allRulesValidity.revocationBackground
            validityLabel.text = "Revoked".localized
            headerBackground.backgroundColor = validityState?.allRulesValidity.revocationBackground
            validityImage.image = validityState?.allRulesValidity.revocationIcon
            
            certificateSections = listItems
            
        } else if let allRulesValidity = validityState?.allRulesValidity {
            dismissButton.setTitle(allRulesValidity.validityButtonTitle, for: .normal)
            dismissButton.backgroundColor = allRulesValidity.validityBackground
            validityLabel.text = allRulesValidity.validityResult
            headerBackground.backgroundColor = allRulesValidity.validityBackground
            validityImage.image = allRulesValidity.validityImage
            
            if isDebugMode && (allRulesValidity != .valid) {
                debugSections.removeAll()
                debugSections.append(DebugSectionModel(sectionType: .verification))
                debugSections.append(DebugSectionModel(sectionType: .raw))
                certificateSections = debugSections + listItems
                shareButton.isHidden = false
                
            } else {
                certificateSections = listItems
                shareButton.isHidden = true
            }
        }
        infoTable.reloadData()
    }
    
    // MARK: Actions
    @IBAction func settingsButtonAction() {
        self.performSegue(withIdentifier: Constants.showSettingsController, sender: nil)
    }
    
    @IBAction func dissmissButtonAction() {
        dismiss(animated: true, completion: nil)
        dismissDelegate?.userDidDissmis(self)
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        guard let certificate = certificate?.digitalCertificate as? HCert else { return }
        
        let debugLevel = DebugManager.sharedInstance.debugLevel.rawValue
        ZipManager(debugLevel: debugLevel).prepareZipData(certificate) { result in
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
    
    // MARK: - Navigation
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

// MARK: - UITableViewDataSource
extension DCCViewerController: UITableViewDataSource {

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
              let cellID = String(describing: DebugDCCSectionCell.self)
              guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugDCCSectionCell else {
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
                  cell.setupCell(for: debugSection, cert: certificate)
                  cell.delegate = self
                  return cell

              case .verification:
                  let cellID = String(describing: DebugDCCValidationCell.self)
                  guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? DebugDCCValidationCell else {
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

extension DCCViewerController: DebugRawSharing {
    func userDidShare(text: String) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension DCCViewerController: DebugControllerDelegate {
    func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
        validateCertificate()
    }
}
