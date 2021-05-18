//
//  AppDelegate.swift
//  dgp-whitelabel-ios
//
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var coordinator: MainCoordinator?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.makeKeyAndVisible()

        coordinator = MainCoordinator(navigationController: UINavigationController())
        window!.rootViewController = coordinator?.navigationController
        coordinator?.start()

        return true
    }
}
