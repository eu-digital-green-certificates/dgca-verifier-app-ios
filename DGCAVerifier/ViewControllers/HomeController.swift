//
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
//  HomeController.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 4/25/21.
//

import UIKit
import SwiftDGC

class HomeController: UIViewController {
  
    private enum Constants {
      static let scannerSegueID = "scannerSegueID"
    }
    
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var messageLabel: UILabel!
    @IBOutlet fileprivate weak var progresBar: UIProgressView!
    @IBOutlet fileprivate weak var reloadButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLabel.text = "Verifier App".localized
        
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name("LoadingRevocationsNotificationName"), object: nil, queue: .main) { notification in
            let strMessage = notification.userInfo?["name"] as? String ?? "Loading data".localized
            self.messageLabel?.text = strMessage
            let percentage = notification.userInfo?["progress" ] as? Float ?? 0.0
            self.progresBar?.setProgress(min(1.0, percentage), animated: true)
        }
        self.activityIndicator.startAnimating()
        reloadButton.isHidden = true
        DataCenter.prepareLocalData {[unowned self] result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    DGCLogger.logError(error)
                    self.reloadButton.isHidden = false
                    self.activityIndicator.stopAnimating()
                    self.messageLabel?.text = "Failed to load data".localized
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadComplete()
                }
            }
        }
    }
    
    deinit {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    @IBAction func reloadAction() {
        reloadButton.isHidden = true
        DataCenter.prepareLocalData {[unowned self] result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    DGCLogger.logError(error)
                    self.reloadButton.isHidden = false
                    self.activityIndicator.stopAnimating()
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadComplete()
                }
            }
        }
    }
    
    private func loadComplete() {
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        SecureBackground.image = renderer.image { rendererContext in
            self.view.layer.render(in: rendererContext.cgContext)
        }
        if DataCenter.localDataManager.versionedConfig["outdated"].bool == true {
            showAlert(title: "Update Available".localized, subtitle: "This version of the app is out of date.".localized)
        } else {
            performSegue(withIdentifier: Constants.scannerSegueID, sender: nil)
        }
    }
}
