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

let DISMISS_TIMEOUT = 15.0

let validityString = [
  HCertValidity.valid: "Valid ✓",
  HCertValidity.invalid: "Invalid Ⅹ",
]
let buttonText = [
  HCertValidity.valid: "Okay",
  HCertValidity.invalid: "Retry",
]
let backgroundColor = [
  HCertValidity.valid: UIColor(red: 0, green: 0.32708, blue: 0.08872, alpha: 1),
  HCertValidity.invalid: UIColor(red: 0.36290, green: 0, blue: 0, alpha: 1),
]
let textColor = [
  HCertValidity.valid: UIColor(red: 0.37632, green: 1, blue: 0.54549, alpha: 1),
  HCertValidity.invalid: UIColor(red: 1, green: 0.14316, blue: 0.14316, alpha: 1),
]

class CertificateViewerVC: UIViewController {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var validityLabel: UILabel!
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

  var childDismissedDelegate: ChildDismissedDelegate?

  func draw() {
    nameLabel.text = hCert.fullName
    infoTable.reloadData()
    typeSegments.selectedSegmentIndex = [
      HCertType.test,
      HCertType.vaccineOne,
      HCertType.vaccineTwo,
      HCertType.recovery
    ].firstIndex(of: hCert.type) ?? 0
    let validity = hCert.validity
    dismissButton.setTitle(buttonText[validity], for: .normal)
    dismissButton.backgroundColor = textColor[validity]
    dismissButton.setTitleColor(backgroundColor[validity], for: .normal)
    validityLabel.text = validityString[validity]
    validityLabel.textColor = textColor[validity]
    view.backgroundColor = backgroundColor[validity]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // selected option color
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    // color of other options
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)

    infoTable.dataSource = self

    return
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadingBackground.layer.zPosition = -1
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
  }

  @IBAction
  func closeButton() {
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
