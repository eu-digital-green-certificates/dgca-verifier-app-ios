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
//  VerificationStatusController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 04.09.22.
//  
        

import Foundation
import UIKit
import DGCCoreLibrary

class VerificationStatusController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    var verificationResult: ScanQRController.VerificationResult?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? StatusViewController,
           segue.identifier == "toSuccessSegue" {
            vc.verificationStatus = self.verificationResult
            vc.parentView = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.containerView.backgroundColor = UIColor.clear
        self.containerView.layer.cornerRadius = 14
    }

}
