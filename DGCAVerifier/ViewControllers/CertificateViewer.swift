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

let dismissTimeout = 15.0

let validityIcon = [
  HCertValidity.valid: UIImage(named: "check")!,
  HCertValidity.invalid: UIImage(named: "error")!
]
let buttonText = [
  HCertValidity.valid: l10n("btn.done"),
  HCertValidity.invalid: l10n("btn.retry")
]
let backgroundColor = [
  HCertValidity.valid: UIColor(named: "green")!,
  HCertValidity.invalid: UIColor(named: "red")!
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

  var hCert: HCert?
  
  weak var childDismissedDelegate: CertViewerDelegate?
  var settingsOpened = false

  func draw() {
    guard var hCert = hCert else {
      return
    }
    typeSegments.tintColor = .white
    // selected option color
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black!], for: .selected)
    // color of other options
    typeSegments.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.disabledText!], for: .normal)
    typeSegments.backgroundColor = UIColor(white: 1.0, alpha: 0.06)

    infoTable.dataSource = self
    infoTable.contentInset = .init(top: 0, left: 0, bottom: 32, right: 0)
    settingsOpened = false
    loadingBackground.isUserInteractionEnabled = false
    nameLabel.text = hCert.fullName
    infoTable.reloadData()
    typeSegments.selectedSegmentIndex = [
      HCertType.test,
      HCertType.vaccine,
      HCertType.recovery
    ].firstIndex(of: hCert.type) ?? 0
    let certType = getCertificationType(type: hCert.type)
    var validity = hCert.validity
    if validity == .valid {
      if let countryCode = hCert.ruleCountryCode {
        let valueSets = ValueSetsDataStorage.sharedInstance.getValueSetsForExternalParameters()
        let externalParameters = ExternalParameter(validationClock: Date(), valueSets: valueSets, countryCode: countryCode, exp: hCert.exp, iat: hCert.iat, certificationType: certType)
        let result = CertLogicEngineManager.sharedInstance.validate(external: externalParameters, payload: hCert.body.description)
        let failsAndOpen = result.filter { validationResult in
          return validationResult.result != .passed
        }
        if failsAndOpen.count > 0 {
          validity = .invalid
          if hCert.info.count > 0 {
            let preferredLanguage = Locale.preferredLanguages[0] as String
            let arr = preferredLanguage.components(separatedBy: "-")
            let deviceLanguage = (arr.first ?? "EN")
            var errorString = ""
            if let error = failsAndOpen[0].rule?.getLocalizedErrorString(locale: deviceLanguage) {
              errorString = error
            }
            if let rule = failsAndOpen[0].rule {
              errorString += errorString + CertLogicEngineManager.sharedInstance.getRuleDetailsError(rule: rule, external: externalParameters)
            }
            self.hCert?.makeSectionForRuleError(errorString: errorString)
            self.infoTable.reloadData()
          }
        }
      }
    }
    dismissButton.setTitle(buttonText[validity], for: .normal)
    dismissButton.backgroundColor = backgroundColor[validity]
    validityLabel.text = validity.l10n
    headerBackground.backgroundColor = backgroundColor[validity]
    validityImage.image = validityIcon[validity]
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if #available(iOS 13.0, *) {
      draw()
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.draw()
      }
    }
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
  var listItems: [InfoSection] {
    hCert?.info.filter {
      !$0.isPrivate
    } ?? []
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let base = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
    guard let cell = base as? InfoCell else {
      return base
    }
    cell.draw(listItems[indexPath.row])
    return cell
  }
}

// MARK: External CertType from HCert type
extension CertificateViewerVC {
  func getCertificationType(type: SwiftDGC.HCertType) -> CertificateType {
    var certType: CertificateType = .general
    switch type {
    case .recovery:
      certType = .recovery
    case .test:
      certType = .test
    case .vaccine:
      certType = .vacctination
    }
    return certType
  }
}
