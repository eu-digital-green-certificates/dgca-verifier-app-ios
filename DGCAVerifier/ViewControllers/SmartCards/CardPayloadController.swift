//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-wallet-app-ios
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
//  PayloadController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 13.04.22.
//  
        

import UIKit
import DGCVerificationCenter
#if canImport(DGCSHInspection)
import DGCSHInspection
#endif

class CardPayloadController: UIViewController {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var payloadTextView: UITextView!
    
    var certificate: MultiTypeCertificate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCardShadow()
#if canImport(DGCSHInspection)
        if let shCert = certificate?.digitalCertificate as? SHCert {
            payloadTextView.text = shCert.prettyBody
        }
#endif
    }
    
    private func setupCardShadow() {
        cardView.layer.shadowOpacity = 0.7
        cardView.layer.shadowOffset = CGSize(width: 3, height: 3)
        cardView.layer.shadowRadius = 15.0
        cardView.layer.shadowColor = UIColor.darkGray.cgColor
    }
}
