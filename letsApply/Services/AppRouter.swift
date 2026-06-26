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

    static func showMainApp(selectedIndex: Int = 0, profileSetupMode: Bool = false) {
        setRootViewController(MainTabBarController(initialSelectedIndex: selectedIndex, profileSetupMode: profileSetupMode))
    }

    static func showProfileSetup() {
        showMainApp(selectedIndex: 2, profileSetupMode: true)
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
