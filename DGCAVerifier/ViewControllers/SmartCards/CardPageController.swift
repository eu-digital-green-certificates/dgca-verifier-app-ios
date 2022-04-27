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
//  CardPageController.swift
//  DGCAVerifier
//  
//  Created by Paul Ballmann on 13.04.22.
//  
        

import UIKit
import DGCVerificationCenter

class CardPageController: UIPageViewController {
    var controllers: [UIViewController] = []
    var certificate: MultiTypeCertificate?
    var editMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let cardView = self.storyboard?.instantiateViewController(withIdentifier: "CardController") as? CardController else { return }
        
        delegate = self
        dataSource = self
        
        cardView.certificate = self.certificate
        cardView.editMode = self.editMode
        controllers.append(cardView)
        guard let payloadController = self.storyboard?.instantiateViewController(withIdentifier: "CardPayloadController") as? CardPayloadController else { return }
        payloadController.certificate = certificate
        controllers.append(payloadController)
        
        setViewControllers([cardView], direction: .forward, animated: true)
    }
}

extension CardPageController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController) else { return nil }
        return index == 0 ? nil : controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController) else { return nil }
        return index == controllers.count - 1 ? nil : controllers[index + 1]
    }
}
