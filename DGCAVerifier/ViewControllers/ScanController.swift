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
import FloatingPanel

class ScanController: SwiftDGC.ScanCertificateController {
  var presentingViewer: UIViewController?

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
  
  func presentViewer(for certificate: HCert) {
    guard presentingViewer == nil,
      let viewerController = UIStoryboard(name: "CertificateViewer", bundle: nil).instantiateInitialViewController() as?
        CertificateViewerVC
    else { return }
    
    viewerController.hCert = certificate
    viewerController.childDismissedDelegate = self
    showFloatingPanel(for: viewerController)
  }
  
  func showFloatingPanel(for controller: UIViewController) {
    let panelController = FloatingPanelController()
    panelController.set(contentViewController: controller)
    panelController.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    panelController.layout = FullFloatingPanelLayout()
    panelController.surfaceView.layer.cornerRadius = 24.0
    panelController.surfaceView.clipsToBounds = true
    panelController.delegate = self
    presentingViewer = controller
    
    present(panelController, animated: true, completion: nil)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
}

extension ScanController: ScanCertificateDelegate {
  func scanController(_ controller: ScanCertificateController, didScanCertificate certificate: HCert) {
    presentViewer(for: certificate)
  }
  
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }
  
  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }
}

extension ScanController: CertViewerDelegate {
  @IBAction func openSettings() {
    guard presentingViewer == nil,
      let viewerController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as? SettingsVC
    else { return }
    
    viewerController.childDismissedDelegate = self
    showFloatingPanel(for: viewerController)
  }

  func childDismissed() {
    presentingViewer = nil
  }
}

extension ScanController: FloatingPanelControllerDelegate {
  func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
    let pos = location.y / view.bounds.height
    if pos >= 0.33 {
      return true
    }
    let threshold: CGFloat = 5.0
    switch fpc.layout.position {
    case .top:
        return (velocity.dy <= -threshold)
    case .left:
        return (velocity.dx <= -threshold)
    case .bottom:
        return (velocity.dy >= threshold)
    case .right:
        return (velocity.dx >= threshold)
    }
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
        self?.presentViewer(for: hCert)
      } else {
        let alertController: UIAlertController = {
            let controller = UIAlertController(title: l10n("error"),
                                               message: l10n("read.dcc.from.nfc"),
                                               preferredStyle: .alert)
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
