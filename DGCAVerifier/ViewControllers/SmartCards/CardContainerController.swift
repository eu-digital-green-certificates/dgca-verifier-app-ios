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
//  CardContainerController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 08.04.22.
//  
        

import UIKit
import DGCVerificationCenter
import DGCCoreLibrary

#if canImport(DGCSHInspection)
import DGCSHInspection
#endif

class CardContainerController: UIViewController {
	@IBOutlet weak var smartCardView: UIView!
	
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    var certificate: MultiTypeCertificate?
    var editMode: Bool = false
    weak var dismissDelegate: DismissControllerDelegate?

    override func viewDidLoad() {
		super.viewDidLoad()
        setupView()
	}
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationController = segue.destination as? CardPageController,
            segue.identifier == "pageEmbedSegue" {
            destinationController.certificate = self.certificate
            destinationController.editMode = self.editMode
        }
    }
    
	private func setupView() {
        self.saveButton.isHidden = editMode
        self.saveButton.setTitle("Retry".localized, for: .normal)
    }
    	
	@IBAction func didPressDoneBtn(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.dismissDelegate?.userDidDissmis(self)
	}
	
	@IBAction func didPressSaveBtn(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.dismissDelegate?.userDidDissmis(self)
    }
}
