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
//  ScanQRController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 04.09.22.
//  
        

import Foundation
import UIKit

class ScanQRController: UIViewController {

    private var verificationResult: VerificationResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction
    public func didSuccess(for button: UIButton) {
        self.verificationResult = .success
        self.performSegue(withIdentifier: "toVerificationStatus", sender: nil)
    }
    
    @IBAction
    public func didError(for button: UIButton) {
        self.verificationResult = .success
        self.performSegue(withIdentifier: "toVerificationStatus", sender: nil)
    }
    
    @IBAction
    public func didInvalid(for button: UIButton) {
        self.verificationResult = .invalid
        self.performSegue(withIdentifier: "toVerificationStatus", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as? VerificationStatusController
        destinationVC?.verificationResult = self.verificationResult
    }
}

extension ScanQRController {
    public enum VerificationResult: String {
        case success = "success"  // verification passed
        case invalid = "invalid"  // verification success but cert invalid
        case error = "error"      // verification technical error
    }


}
