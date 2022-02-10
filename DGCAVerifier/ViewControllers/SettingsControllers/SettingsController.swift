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
//  SettingsController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/19/21.
//

import UIKit
import SwiftDGC

class SettingsController: UITableViewController, DebugControllerDelegate {
  private enum Constants {
    static let licenseSegueID = "LicensesVC"
    static let debugSegueID = "DebugVC"
  }

  weak var delegate: DebugControllerDelegate?
  weak var dismissDelegate: DismissControllerDelegate?
  var isNavigating = false
  
  @IBOutlet fileprivate weak var licensesLabelName: UILabel!
  @IBOutlet fileprivate weak var privacyLabelName: UILabel!
  @IBOutlet fileprivate weak var debugLabelName: UILabel!
  @IBOutlet fileprivate weak var debugLabel: UILabel!
  @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet fileprivate weak var versionLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    debugLabelName.text = "Debug mode".localized
    licensesLabelName.text = "Licenses".localized
    privacyLabelName.text = "Privacy Information".localized
    versionLabel.text = DataCenter.appVersion
    updateInterface()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isNavigating = false
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if !isNavigating  {
      delegate?.debugControllerDidSelect(isDebugMode: DebugManager.sharedInstance.isDebugMode,
          level: DebugManager.sharedInstance.debugLevel)
    }
  }

  
  private func updateInterface() {
    if !DebugManager.sharedInstance.isDebugMode {
      debugLabel.text = "Disabled".localized
    } else {
      switch DebugManager.sharedInstance.debugLevel {
      case .level1:
        debugLabel.text = "Level 1".localized
      case .level2:
        debugLabel.text = "Level 2".localized
      case .level3:
        debugLabel.text = "Level 3".localized
       }
    }
  }
  
  func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
    updateInterface()
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch section {
    case 1:
      let format = "Last updated: %@".localized
      return String(format: format, DataCenter.lastFetch.dateTimeString)
    default:
      return nil
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

      switch indexPath.section {
      case 0:
          if indexPath.row == 0 {
            openPrivacyDoc()
          } else if indexPath.row == 1 {
            openLicenses()
          } else if indexPath.row == 2 {
            openDebugSettings()
          }
      case 1:
        reloadAllData()
      default:
          break
      }
  }
  
  func reloadAllData() {
    activityIndicator.startAnimating()
    DataCenter.reloadStorageData { result in
      DispatchQueue.main.async { [weak self] in
        self?.activityIndicator.stopAnimating()
        self?.tableView.reloadData()
      }
    }
  }

  func openPrivacyDoc() {
    let link = DataCenter.localDataManager.versionedConfig["privacyUrl"].string ?? ""
    openUrl(link)
  }

  func openEuCertDoc() {
    let link = SharedConstants.linkToOopenEuCertDoc
    openUrl(link)
  }

  func openGitHubSource() {
    let link = SharedConstants.linkToOpenGitHubSource
    openUrl(link)
  }

  func openDebugSettings() {
    performSegue(withIdentifier: Constants.debugSegueID, sender: self)
  }

  func openLicenses() {
    isNavigating = true
    performSegue(withIdentifier: Constants.licenseSegueID, sender: self)
  }

  func openUrl(_ string: String!) {
    if let url = URL(string: string) {
      UIApplication.shared.open(url)
    }
  }

  @IBAction func dismissAction() {
    dismiss(animated: true, completion: nil)
    dismissDelegate?.userDidDissmis(self)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.debugSegueID:
      if let destinationController = segue.destination as? DebugVC {
        destinationController.delegate = self
      }
    default:
      break
    }
  }
}

