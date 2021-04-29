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
//  PatientScannerDemo
//  
//  Created by Yannick Spreen on 4/25/21.
//  
        

import Foundation
import UIKit

class HomeVC: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    GatewayConnection.timer?.invalidate()
    LocalData.initialize {
      DispatchQueue.main.async { [weak self] in
        guard let self = self else {
          return
        }
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        SecureBackground.image = renderer.image { rendererContext in
          self.view.layer.render(in: rendererContext.cgContext)
        }
        self.performSegue(withIdentifier: "scanner", sender: self)
      }
    }
  }
}
