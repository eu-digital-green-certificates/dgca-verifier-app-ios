/*
 *  license-start
 *  
 *  Copyright (C) 2021 Ministero della Salute and all other contributors
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
*/

//
//  ResultViewController.swift
//  dgp-whitelabel-ios
//
//

import UIKit

protocol VerificationCoordinator: Coordinator {
    func dismissVerification()
}

class VerificationViewController: UIViewController {
    
    private weak var coordinator: VerificationCoordinator?
    private var viewModel: VerificationViewModel
    
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rescanButton: UIButton!
    
    @IBOutlet weak var contentStackView: UIStackView!
    
    // MARK: - Init
    
    init(coordinator: VerificationCoordinator, viewModel: VerificationViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(nibName: "VerificationViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultImageView.image = UIImage(named: viewModel.imageName)
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        rescanButton.setTitle(viewModel.rescanButtonTitle, for: .normal)
        
        viewModel.resultItems?.forEach {
            if let resultView = Bundle.main.loadNibNamed("ResultView", owner: nil, options: nil)?.first as? ResultView {
                resultView.configure(with: $0)
                contentStackView.addArrangedSubview(resultView)
            }
        }
    }
    
    @IBAction func dismiss(_ sender: Any) {
        coordinator?.dismissVerification()
    }
}
