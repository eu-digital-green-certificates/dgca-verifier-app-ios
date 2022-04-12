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
//  DebugCountryCell.swift
//  DGCAVerifier
//  
//  Created by Alexandr Chernyy on 02.09.2021.
//  


import UIKit
import DGCCoreLibrary

class DebugCountryCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    private var country: CountryModel? {
        didSet {
            setupView()
        }
    }

    func setupView() {
        guard let nameLabel = nameLabel, let country = country else {
            nameLabel.text = ""
            return
        }
        nameLabel.text = country.name
    }
    
    func setCountry(countryModel: CountryModel) {
        country = countryModel
    }
}
