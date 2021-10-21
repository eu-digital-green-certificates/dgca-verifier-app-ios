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
//  Home.swift
//  DGCAVerifier
//  
//  Created by Yannick Spreen on 4/25/21.
//  

import Foundation
import UIKit
import SwiftDGC

class HomeVC: UIViewController {
  private enum Constants {
    static let scannerSegueID = "scannerSegueID"
  }
  var loaded = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    VerificationManager.sharedManager.config = HCertConfig()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    loaded ? loadComplete() : load()
  }

  func load() {
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
    LocalData.initialize {
      DispatchQueue.main.async { [unowned self] in
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        SecureBackground.image = renderer.image { rendererContext in
          self.view.layer.render(in: rendererContext.cgContext)
        }
        self.loaded = true
        loadingGroup.leave()
      }
    }
    loadingGroup.notify(queue: .main) { [unowned self] in
      self.loadComplete()
    }
  }

  func loadComplete() {
    if LocalData.sharedInstance.versionedConfig["outdated"].bool == true {
      showAlert(title: l10n("info.outdated"), subtitle: l10n("info.outdated.body"))
      return
    }
    performSegue(withIdentifier: Constants.scannerSegueID, sender: nil)
  }
}
