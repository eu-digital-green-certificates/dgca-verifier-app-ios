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
//  ScanController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import SwiftDGC

class ScanController: SwiftDGC.ScanCertificateController {
  private struct Constants {
    static let showSettingsSegueID = "showSettingsSegueID"
    static let showCertificateViewer = "showCertificateViewer"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setVisibleCountrySelection(visible: true)
    delegate = self
    GatewayConnection.countryList { countryList in
      DispatchQueue.main.async {
        self.setListOfRuleCounties(list: countryList)
      }
    }
    GatewayConnection.initialize()
    let settingsButton = setupSettingsButton()

    setupNFCButton(constraintView: settingsButton)
  }
  
  private func setupSettingsButton() -> UIButton {
    let settingsButton = UIButton(frame: .zero)
    settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    settingsButton.setBackgroundImage(UIImage(named: "gear_white"), for: .normal)
    view.addSubview(settingsButton)
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      settingsButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 36.0),
      settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24.0),
      settingsButton.heightAnchor.constraint(equalToConstant: 30),
      settingsButton.widthAnchor.constraint(equalToConstant: 30)
    ])
    return settingsButton
  }
  
  private func setupNFCButton(constraintView box: UIView) {
    let settingsButton = box
    let nfcButton = UIButton(frame: .zero)
    nfcButton.addTarget(self, action: #selector(scanNFC), for: .touchUpInside)
    nfcButton.translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 13.0, *) {
      nfcButton.setBackgroundImage(UIImage(named: "icon_nfc")?.withTintColor(.white), for: .normal)
    } else {
      nfcButton.setBackgroundImage(UIImage(named: "icon_nfc"), for: .normal)
    }
    view.addSubview(nfcButton)
    let guide = view.safeAreaLayoutGuide
    
    NSLayoutConstraint.activate([
      nfcButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 32.0),
      nfcButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24.0),
      nfcButton.heightAnchor.constraint(equalToConstant: 30),
      nfcButton.widthAnchor.constraint(equalToConstant: 30)
    ])
  }
  
  @objc func openSettings() {
    performSegue(withIdentifier: Constants.showSettingsSegueID, sender: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case Constants.showCertificateViewer:
      if let destinationController = segue.destination as? CertificateViewerVC,
          let certificate = sender as? HCert {
        destinationController.hCert = certificate
      }
    default:
      break
    }
  }
}

extension ScanController: ScanCertificateDelegate {
  func scanController(_ controller: ScanCertificateController, didScanCertificate certificate: HCert) {
    performSegue(withIdentifier: Constants.showCertificateViewer, sender: certificate)
  }
  
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }
  
  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }
}

extension ScanController {
  @objc private func scanNFC() {
    let helper = NFCHelper()
    helper.onNFCResult = onNFCResult(success:msg:)
    helper.restartSession()
  }
  
  func onNFCResult(success: Bool, msg: String) {
    DispatchQueue.main.async { [weak self] in
      print("\(msg)")
      if success, var hCert = HCert(from: msg, applicationType: .wallet) {
        hCert.ruleCountryCode = self?.getSelectedCountryCode()
        self?.performSegue(withIdentifier: Constants.showCertificateViewer, sender: hCert)
      } else {
        let alertController: UIAlertController = {
            let controller = UIAlertController(title: l10n("error"),
                message: l10n("read.dcc.from.nfc"), preferredStyle: .alert)
          let actionRetry = UIAlertAction(title: l10n("retry"), style: .default) { _ in
            self?.scanNFC()
          }
          controller.addAction(actionRetry)
          let actionOk = UIAlertAction(title: l10n("ok"), style: .default)
          controller.addAction(actionOk)
          return controller
        }()
        self?.present(alertController, animated: true)
      }
    }
  }
}
