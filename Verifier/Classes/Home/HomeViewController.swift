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
//  HomeViewController.swift
//  dgp-whitelabel-ios
//
//

import UIKit

protocol HomeCoordinator: Coordinator {
    func showCamera()
}

class HomeViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private var viewModel: HomeViewModel

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var pageTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!

    @IBOutlet weak var scanButton: UIButton!

    @IBOutlet weak var updateStatusLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var loadingActivityView: UIActivityIndicatorView!

    init(coordinator: HomeCoordinator, viewModel: HomeViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel                

        super.init(nibName: "HomeViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "home.title".localized

        scanButton.setTitle("home.scan".localized, for: .normal)

        pageTitleLabel.text = "home.subtitle".localized
        descriptionLabel.text = "home.description".localized
        welcomeLabel.text = "home.welcome".localized
        introLabel.text = "home.intro".localized
        
        updateStatusLabel.text = viewModel.lastUpdateText.value
        viewModel.lastUpdateText.add(observer: self) { [weak self] text in
            DispatchQueue.main.async {
                self?.updateStatusLabel.text = text
            }
        }
        
        versionLabel.text = "home.version".localized + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")

        scanButton.isEnabled = viewModel.isScanEnabled.value ?? true
        viewModel.isScanEnabled.add(observer: self) { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.scanButton.isEnabled = isEnabled ?? true
            }
        }

        loadingActivityView.startAnimating()
        viewModel.isLoading.add(observer: self) { [weak self] isLoading in
            DispatchQueue.main.async {
                (isLoading ?? false) ? self?.loadingActivityView.startAnimating() : self?.loadingActivityView.stopAnimating()
            }
        }
        
        viewModel.isVersionOutdated.add(observer: self) { [weak self] isVersionOutdated in
            DispatchQueue.main.async {
                if isVersionOutdated ?? false {
                    self?.showOutdatedAlert()
                }
            }
        }
        
        viewModel.loadCertificates()
//        scanButton.isEnabled = true
//        updateStatusLabel.text = "Test certificate loaded locally"
//        LocalData.sharedInstance.add(encodedPublicKey: mockCertificate)
    }
    
    private func showOutdatedAlert() {
        let alertController = UIAlertController(title: "alert.versionOutdated.title".localized, message: "alert.versionOutdated.message".localized, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)  { _ in
            if let url = URL(string: "itms-apps://apple.com/app/id1565800117"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    private func showNoKeysAlert() {
        let alertController = UIAlertController(title: "alert.noKeys.title".localized, message: "alert.noKeys.message".localized, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func scan(_ sender: Any) {
        if viewModel.isVersionOutdated.value ?? false {
            showOutdatedAlert()
        } else if LocalData.sharedInstance.lastFetch.timeIntervalSince1970 == 0 {
            showNoKeysAlert()
        }
        else {
            coordinator?.showCamera()
        }
    }
}
