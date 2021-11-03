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

  var loaded = false
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    loaded ? loadComplete() : load()
  }

  func load() {
    self.activityIndicator.startAnimating()
    
    let loadingGroup = DispatchGroup()
    GatewayConnection.timer?.invalidate()

    loadingGroup.enter()
    RulesDataStorage.initialize {
      GatewayConnection.rulesList { _ in
        CertLogicEngineManager.sharedInstance.setRules(ruleList: RulesDataStorage.sharedInstance.rules)
        loadingGroup.leave()
      }
      loadingGroup.enter()
      GatewayConnection.loadRulesFromServer { _ in
        CertLogicEngineManager.sharedInstance.setRules(ruleList: RulesDataStorage.sharedInstance.rules)
        loadingGroup.leave()
      }
    }
    loadingGroup.enter()
    ValueSetsDataStorage.initialize {
      GatewayConnection.valueSetsList { _ in
        loadingGroup.leave()
      }
      loadingGroup.enter()
      GatewayConnection.loadValueSetsFromServer { _ in
        loadingGroup.leave()
      }
    }
    loadingGroup.enter()
    LocalStorage.dataKeeper.initialize {
      DispatchQueue.main.async { [unowned self] in
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        SecureBackground.image = renderer.image { rendererContext in
          self.view.layer.render(in: rendererContext.cgContext)
        }
        loadingGroup.leave()
      }
    }
    loadingGroup.notify(queue: .main) { [unowned self] in
      self.loaded = true
      self.activityIndicator.stopAnimating()
      self.loadComplete()
    }
  }

  func loadComplete() {
    if LocalStorage.dataKeeper.versionedConfig["outdated"].bool == true {
      showAlert(title: l10n("info.outdated"), subtitle: l10n("info.outdated.body"))
      return
    }
    performSegue(withIdentifier: Constants.scannerSegueID, sender: nil)
  }
}