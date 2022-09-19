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
//  StatusViewController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 05.09.22.
//  
        

import Foundation
import UIKit

class StatusViewController: UIViewController {
    
    var verificationStatus: ScanQRController.VerificationResult?
    var parentView: UIViewController?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headline: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var divider1: UIView!
    @IBOutlet weak var divider2: UIView!
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func setupUI() {
        switch self.verificationStatus {
        case .success:
            self.setupSuccessView()
        case .error:
            self.setupErrorView()
        case .invalid:
            self.setupInvalidView()
        default: break;
        }
    }
    
    @IBAction func didCancel(_ sender: UIButton) {
        self.parentView?.navigationController?.popViewController(animated: true)
    }
    
    func setupSuccessView() {
        self.imageView.image = UIImage(named: "checkmark.circle.png")
        self.headline.text = "Success"
        self.subtitle.isHidden = true
        self.divider1.isHidden = true
        self.divider2.isHidden = true
        self.button1.isHidden = true
        self.button2.isHidden = true
    }
        
    func setupErrorView() {
        self.imageView.image = UIImage(named: "verifier_icon.png")
        self.headline.text = "Failed to validate"
        self.subtitle.text = "Try again"
    }
    
    func setupInvalidView() {
        self.imageView.image = UIImage(named: "verifier_icon.png")
        self.headline.text = "Certificate not valid"
        self.button1.isHidden = true
        self.divider1.isHidden = true
    }
}
