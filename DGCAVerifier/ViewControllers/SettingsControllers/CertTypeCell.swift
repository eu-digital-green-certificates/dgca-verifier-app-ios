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
//  CertTypeCell.swift
//  DGCAVerifier
//  
//  Created by Igor Khomiak on 10.04.2022.
//  
        

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

class CertTypeCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var certTypeName: UILabel!
    @IBOutlet fileprivate weak var certTaskName: UILabel!
    @IBOutlet fileprivate weak var lastUpdateLabel: UILabel!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    var delegate: DataManagingProtocol?
    
    var applicableInspector: ApplicableInspector? {
        didSet {
            certTypeName.text = applicableInspector?.type.certificateDescription
            certTaskName.text = applicableInspector?.type.certificateTaskDescription
            let dateString = applicableInspector?.inspector.lastUpdate.dateTimeString ?? ""
            lastUpdateLabel.text = "Last updated: ".localized + dateString
        }
    }
    
    @IBAction func reloadDataAction() {
        activityIndicator.startAnimating()
        guard let applicableInspector = applicableInspector else { return }
        
        applicableInspector.inspector.updateLocallyStoredData(appType: .verifier) { [weak self] rezult in
            if case let .failure(error) = rezult {
                self?.delegate?.loadingInspector(applicableInspector, didFailLoadingDataWith: error)
                return
            }
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
            }
            self?.delegate?.loadingInspector(self!.applicableInspector!, didFinishLoadingData: true)
        }
    }
}
