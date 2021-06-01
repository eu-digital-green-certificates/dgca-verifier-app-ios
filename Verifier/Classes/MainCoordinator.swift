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
//  MainCoordinator.swift
//  verifier-ios
//
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}

class MainCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        let controller = HomeViewController(coordinator: self, viewModel: HomeViewModel())
        navigationController.pushViewController(controller, animated: true)
    }
}

extension MainCoordinator: HomeCoordinator {
    func showCamera() {
        let controller = CameraViewController(coordinator: self)
        navigationController.pushViewController(controller, animated: true)
    }
}

extension MainCoordinator: CameraCoordinator {
    func showVerificationFor(payloadString: String) {
        let controller = VerificationViewController(coordinator: self,
                                                    viewModel: VerificationViewModel(qrCodeText: payloadString))
        navigationController.present(controller, animated: true)
    }
    func dismissCamera() {
        navigationController.popViewController(animated: true)
    }
}

extension MainCoordinator: VerificationCoordinator {
    func dismissVerification() {
        navigationController.dismiss(animated: true, completion: nil)
    }
}
