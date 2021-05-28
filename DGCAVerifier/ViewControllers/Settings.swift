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
import FloatingPanel
import SwiftDGC

class SettingsVC: UINavigationController {
  weak var childDismissedDelegate: CertViewerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    additionalSafeAreaInsets.top = 16.0
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    childDismissedDelegate?.childDismissed()
  }
}

class SettingsTableVC: UITableViewController {
  var loading = false

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    let format = l10n("settings.last-updated")

    return [
      "",
      String(format: format, LocalData.sharedInstance.lastFetch.dateTimeString),
      "",
      ""
    ][section]
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

    if indexPath.section == 0 && indexPath.row == 0 {
      openPrivacyDoc()
    }
    if indexPath.section == 1 {
      loading = true
      tableView.reloadData()
      return GatewayConnection.update {
        DispatchQueue.main.async { [weak self] in
          self?.loading = false
          self?.tableView.reloadData()
        }
      }
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

  func openUrl(_ string: String!) {
    if let url = URL(string: string) {
      UIApplication.shared.open(url)
    }
  }

  @IBAction
  func cancelButton() {
    dismiss(animated: true, completion: nil)
  }
}
