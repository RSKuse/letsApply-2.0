//
//  MainTabBarController.swift
//  letsApply
//


import UIKit

class MainTabBarController: UITabBarController {

    private let initialSelectedIndex: Int
    private let profileSetupMode: Bool

    init(initialSelectedIndex: Int = 0, profileSetupMode: Bool = false) {
        self.initialSelectedIndex = initialSelectedIndex
        self.profileSetupMode = profileSetupMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.initialSelectedIndex = 0
        self.profileSetupMode = false
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabs()
        configureTabBarAppearance()
        selectedIndex = initialSelectedIndex
    }

    private func setupTabs() {

        let homeVC = UINavigationController(
            rootViewController: HomeViewController()
        )

        let jobsVC = UINavigationController(
            rootViewController: JobsViewController()
        )

        let profileRootVC = ProfileViewController()
        profileRootVC.isProfileSetupMode = profileSetupMode

        let profileVC = UINavigationController(rootViewController: profileRootVC)

        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house.fill"),
            tag: 0
        )

        jobsVC.tabBarItem = UITabBarItem(
            title: "Jobs",
            image: UIImage(systemName: "briefcase.fill"),
            tag: 1
        )

        profileVC.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.fill"),
            tag: 2
        )

        viewControllers = [
            homeVC,
            jobsVC,
            profileVC
        ]
    }

    private func configureTabBarAppearance() {
        tabBar.tintColor = AppTheme.brand
        tabBar.unselectedItemTintColor = AppTheme.secondaryText
        tabBar.backgroundColor = AppTheme.surface
    }
}
