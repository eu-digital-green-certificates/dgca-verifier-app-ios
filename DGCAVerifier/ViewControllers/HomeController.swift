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

  var downloadedDataHasExpired: Bool {
    return DataCenter.lastFetch.timeIntervalSinceNow < -SharedConstants.expiredDataInterval
  }
 
  var appWasRunWithOlderVersion: Bool {
    return DataCenter.lastLaunchedAppVersion != DataCenter.appVersion
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    appNameLabel.text = "Verifier App"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    DataCenter.initializeLocalData {[unowned self] result in
      DispatchQueue.main.async {
        self.downloadedDataHasExpired || self.appWasRunWithOlderVersion ?  self.reloadStorageData() : self.initializeAllStorageData()
      }
    }
  }

  func initializeAllStorageData() {
    self.activityIndicator.startAnimating()
    
    DataCenter.initializeAllStorageData { result in
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.loadComplete()
      }
    }
  }
  
  func reloadStorageData() {
    self.activityIndicator.startAnimating()
    
    DataCenter.reloadStorageData { result in
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.loadComplete()
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
      return
    } else {
      performSegue(withIdentifier: Constants.scannerSegueID, sender: nil)
    }
  }
}
