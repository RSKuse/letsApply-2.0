//
//  SceneDelegate.swift
//  letsApply
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = initialViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    private func initialViewController() -> UIViewController {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_SCREEN"] == "cv-studio" {
            return UINavigationController(rootViewController: CVBuilderViewController())
        }
        #endif

        return SplashViewController()
    }
}
