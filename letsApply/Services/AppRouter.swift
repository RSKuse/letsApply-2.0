//
//  AppRouter.swift
//  letsApply
//

import UIKit

final class AppRouter {

    static func showSplash() {
        setRootViewController(SplashViewController())
    }

    static func showOnboarding() {
        setRootViewController(UINavigationController(rootViewController: OnboardingViewController()))
    }

    static func showMainApp() {
        setRootViewController(MainTabBarController())
    }

    static func showProfileSetup() {
        let profileVC = ProfileViewController()
        profileVC.isProfileSetupMode = true
        setRootViewController(UINavigationController(rootViewController: profileVC))
    }

    static func setRootViewController(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            return
        }

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }
}
