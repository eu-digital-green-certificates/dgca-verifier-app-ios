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
import DGCVerificationCenter
import DGCCoreLibrary

class HomeController: UIViewController {
  
    private enum Constants {
        static let scannerSegueID = "scannerSegueID"
    }
    
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var messageLabel: UILabel!
    @IBOutlet fileprivate weak var progresBar: UIProgressView!
    @IBOutlet fileprivate weak var reloadButton: UIButton!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    let verificationCenter = DGCVerificationCenter.shared
    
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
        reloadData()
    }
    
    deinit {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    private func reloadData() {
        reloadButton.isHidden = true
        self.activityIndicator.startAnimating()
        verificationCenter.prepareStoredData(appType: .verifier) {[unowned self] result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    DGCLogger.logError(error)
                    self.activityIndicator.stopAnimating()
                    self.showAlertCannotReload()
                }
            } else if case .noData = result {
                DispatchQueue.main.async {
                    DGCLogger.logInfo("No input data. Possible error - No internet connection")
                    self.reloadButton.isHidden = false
                    self.activityIndicator.stopAnimating()
                    self.showAlertNoData()
                }
                
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadComplete()
                }
            }
        }
    }
    
    @IBAction func reloadAction() {
        reloadData()
    }
    
    private func showAlertNoData() {
        let title = "Cannot load data".localized
        let message = "Please check the internet connection and try again.".localized
        
        let infoAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { action in
        }
        infoAlertController.addAction(action)
        self.present(infoAlertController, animated: true)
    }
    
    func showAlertCannotReload() {
        let alert = UIAlertController(title: "Cannot update stored data".localized, message: "Please update your data later.".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Later".localized, style: .default, handler: { _ in
            self.activityIndicator.stopAnimating()
            self.loadComplete()
        }))
        
        alert.addAction(UIAlertAction(title: "Reload".localized, style: .default, handler: { [unowned self] (_: UIAlertAction!) in
            self.reloadData()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func loadComplete() {
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        SecureBackground.image = renderer.image { rendererContext in
            self.view.layer.render(in: rendererContext.cgContext)
        }
        // performSegue(withIdentifier: Constants.scannerSegueID, sender: nil)
        performSegue(withIdentifier: "toEUIDStoryboardSegue", sender: nil)
    }
}
