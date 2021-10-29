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

class SettingsTableVC: UITableViewController, DebugControllerDelegate {
  var loading = false
  weak var delegate: DebugControllerDelegate?
  
  @IBOutlet weak var licensesLabelName: UILabel!
  @IBOutlet weak var privacyLabelName: UILabel!
  @IBOutlet weak var debugLabelName: UILabel!
  @IBOutlet weak var debugLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    debugLabelName.text = l10n("Debug mode")
    licensesLabelName.text = l10n("Licenses")
    privacyLabelName.text = l10n("Privacy Information")
    updateInterface()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    delegate?.debugControllerDidSelect(isDebugMode: DebugManager.sharedInstance.isDebugMode,
        level: DebugManager.sharedInstance.debugLevel)
  }

  private func updateInterface() {
    if !DebugManager.sharedInstance.isDebugMode {
      debugLabel.text = l10n("Disabled")
    } else {
      switch DebugManager.sharedInstance.debugLevel {
      case .level1:
        debugLabel.text = l10n("Level 1")
      case .level2:
        debugLabel.text = l10n("Level 2")
      case .level3:
        debugLabel.text = l10n("Level 3")
       }
    }
  }
  
  func debugControllerDidSelect(isDebugMode: Bool, level: DebugLevel) {
    updateInterface()
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    let format = l10n("settings.last-updated")
    return [ "", String(format: format, LocalData.sharedInstance.lastFetch.dateTimeString), "", "" ][section]
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    if indexPath.section == 2 {
      cell.alpha = loading ? 1 : 0
      cell.contentView.alpha = loading ? 1 : 0
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

      switch indexPath.section {
      case 0:
          if indexPath.row == 0 {
            openPrivacyDoc()
          } else if indexPath.row == 1 {
              break
          } else if indexPath.row == 2 {
            openDebugSettings()
          }
      case 1:
          loading = true
          tableView.reloadData()
          return GatewayConnection.update {
            DispatchQueue.main.async { [weak self] in
              self?.loading = false
              self?.tableView.reloadData()
            }
          }
      default:
          break
      }
  }

  func openPrivacyDoc() {
    let link = LocalData.sharedInstance.versionedConfig["privacyUrl"].string ?? ""
    openUrl(link)
  }

  func openEuCertDoc() {
    let link = "https://ec.europa.eu/health/ehealth/covid-19_en"
    openUrl(link)
  }

  func openGitHubSource() {
    let link = "https://github.com/eu-digital-green-certificates"
    openUrl(link)
  }

  func openDebugSettings() {
    performSegue(withIdentifier: "DebugVC", sender: self)
  }

  func openUrl(_ string: String!) {
    if let url = URL(string: string) {
      UIApplication.shared.open(url)
    }
  }

  @IBAction func cancelButton() {
    dismiss(animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case "DebugVC":
      if let destinationController = segue.destination as? DebugVC {
        destinationController.delegate = self
      }
    default:
      break
    }
  }
}
