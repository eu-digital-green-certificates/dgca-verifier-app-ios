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
//  ViewController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/8/21.
//
//  https://www.raywenderlich.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes
//

import UIKit
import SwiftDGC
import FloatingPanel

class ScanVC: SwiftDGC.ScanVC {
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
  }

  var presentingViewer: UIViewController?
  func presentViewer(for certificate: HCert) {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    viewer.hCert = certificate
    viewer.childDismissedDelegate = self
    showFloatingPanel(for: viewer)
  }

  func showFloatingPanel(for controller: UIViewController) {
    let fpc = FloatingPanelController()
    fpc.set(contentViewController: controller)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    fpc.delegate = self
    presentingViewer = controller

    present(fpc, animated: true, completion: nil)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
}

extension ScanVC: ScanVCDelegate {
  func disableBackgroundDetection() {
    SecureBackground.paused = true
  }

  func enableBackgroundDetection() {
    SecureBackground.paused = false
  }

  func hCertScanned(_ cert: HCert) {
    presentViewer(for: cert)
  }
}

extension ScanVC: CertViewerDelegate {
  @IBAction
  func openSettings() {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "Settings", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? SettingsVC
    else {
      return
    }

    viewer.childDismissedDelegate = self
    showFloatingPanel(for: viewer)
  }

  func childDismissed() {
    presentingViewer = nil
  }
}

extension ScanVC: FloatingPanelControllerDelegate {
  func floatingPanel(
    _ fpc: FloatingPanelController,
    shouldRemoveAt location: CGPoint,
    with velocity: CGVector
  ) -> Bool {
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
