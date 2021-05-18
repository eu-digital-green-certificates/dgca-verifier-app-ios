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
