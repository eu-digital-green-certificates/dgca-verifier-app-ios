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
//  CardController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 13.04.22.
//  
        

import UIKit
import DGCVerificationCenter

#if canImport(DGCSHInspection)
import DGCSHInspection
#endif

class CardController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    @IBOutlet weak var issuerLabel: UILabel!
    @IBOutlet weak var lastDoseLabel: UILabel!
    @IBOutlet weak var doseCountLabel: UILabel!
    @IBOutlet weak var qrContainerView: UIView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var invalidLabel: UILabel!
    
    var certificate: MultiTypeCertificate?
    var editMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCardShadow()
        loadData()
    }
    
    private func setupView() {
        if !editMode {
            qrContainerView.isHidden = true
        }
    }
    
    private func loadData() {
    #if canImport(DGCSHInspection)
        guard let shCert = self.certificate?.digitalCertificate as? SHCert else { return }

        switch shCert.type {
            case .immunization:
                self.titleLabel.text = "Vaccination Card".localized
                self.subtitleLabel.text = "COVID-19".localized
            case .other:
            self.titleLabel.text = "Smart Health Card".localized
            self.subtitleLabel.isHidden = true
        }
        subtitleLabel.text = shCert.subType.uppercased()
        nameLabel.text = shCert.fullName
        dobLabel.text = shCert.dateOfBirth
        issuerLabel.text = shCert.issuer
        lastDoseLabel.text = shCert.dates.last?.string
        if shCert.firstName == "" && shCert.lastName == "" {
            self.invalidLabel.isHidden = false
            self.invalidLabel.text = "Could not find valid payload information. Swipe right to view all collected data.".localized
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
