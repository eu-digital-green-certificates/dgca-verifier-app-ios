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

let DISMISS_TIMEOUT = 15.0

let validityIcon = [
  HCertValidity.valid: UIImage(named: "check")!,
  HCertValidity.invalid: UIImage(named: "error")!,
]
let buttonText = [
  HCertValidity.valid: l10n("btn.done"),
  HCertValidity.invalid: l10n("btn.retry"),
]
let backgroundColor = [
  HCertValidity.valid: UIColor(named: "green")!,
  HCertValidity.invalid: UIColor(named: "red")!,
]
class CertificateViewerVC: UIViewController {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var validityLabel: UILabel!
  @IBOutlet weak var validityImage: UIImageView!
  @IBOutlet weak var headerBackground: UIView!
  @IBOutlet weak var loadingBackground: UIView!
  @IBOutlet weak var loadingBackgroundTrailing: NSLayoutConstraint!
  @IBOutlet weak var typeSegments: UISegmentedControl!
  @IBOutlet weak var infoTable: UITableView!
  @IBOutlet weak var dismissButton: UIButton!

  var hCert: HCert! {
    didSet {
      self.draw()
    }
  }

  var childDismissedDelegate: CertViewerDelegate?
  var settingsOpened = false

  func draw() {
    nameLabel.text = hCert.fullName
    infoTable.reloadData()
    typeSegments.selectedSegmentIndex = [
      HCertType.test,
      HCertType.vaccine,
      HCertType.recovery
    ].firstIndex(of: hCert.type) ?? 0
    let validity = hCert.validity
    dismissButton.setTitle(buttonText[validity], for: .normal)
    dismissButton.backgroundColor = backgroundColor[validity]
    validityLabel.text = validity.l10n
    headerBackground.backgroundColor = backgroundColor[validity]
    validityImage.image = validityIcon[validity]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // selected option color
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black!], for: .selected)
    // color of other options
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.disabledText!], for: .normal)
    typeSegments.backgroundColor = UIColor(white: 1.0, alpha: 0.06)

    infoTable.dataSource = self
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)

    return
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    settingsOpened = false
    loadingBackground.isUserInteractionEnabled = false
    loadingBackgroundTrailing.priority = .init(200)
    UIView.animate(withDuration: DISMISS_TIMEOUT, delay: 0, options: .curveLinear) { [weak self] in
      self?.view.layoutIfNeeded()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + DISMISS_TIMEOUT) { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }

    return
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
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return hCert.info.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let base = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
    guard let cell = base as? InfoCell else {
      return base
    }
    cell.draw(hCert.info[indexPath.row])
    return cell
  }
}
