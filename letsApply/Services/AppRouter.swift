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
        guard let window = activeWindow() else { return }

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }

    private static func activeWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
