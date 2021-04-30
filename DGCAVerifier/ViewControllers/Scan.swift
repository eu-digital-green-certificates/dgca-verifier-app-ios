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

    delegate = self
    GatewayConnection.initialize()
    let settingsButton = UIButton(frame: .zero)
    settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    settingsButton.setImage(UIImage(named: "gear_white"), for: .normal)
    view.addSubview(settingsButton)
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      settingsButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 32.0),
      settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24.0),
    ])
  }

  var presentingViewer: CertificateViewerVC?
  func presentViewer(for certificate: HCert) {
    guard
      presentingViewer == nil,
      let contentVC = UIStoryboard(name: "CertificateViewer", bundle: nil)
        .instantiateInitialViewController(),
      let viewer = contentVC as? CertificateViewerVC
    else {
      return
    }

    let fpc = FloatingPanelController()
    fpc.set(contentViewController: viewer)
    fpc.isRemovalInteractionEnabled = true // Let it removable by a swipe-down
    fpc.layout = FullFloatingPanelLayout()
    fpc.surfaceView.layer.cornerRadius = 24.0
    fpc.surfaceView.clipsToBounds = true
    viewer.hCert = certificate
    viewer.childDismissedDelegate = self
    presentingViewer = viewer

    present(fpc, animated: true, completion: nil)
  }
}

extension ScanVC: ScanVCDelegate {
  func hCertScanned(_ cert: HCert) {
    presentViewer(for: cert)
  }
}

extension ScanVC: CertViewerDelegate {
  @IBAction
  func openSettings() {
    print("Open Settings") // TODO
  }

  func childDismissed() {
    presentingViewer = nil
  }
}
