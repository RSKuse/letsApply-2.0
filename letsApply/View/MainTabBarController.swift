//
//  MainTabBarController.swift
//  letsApply
//


import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabs()
        configureTabBarAppearance()
    }

    private func setupTabs() {

        let homeVC = UINavigationController(
            rootViewController: HomeViewController()
        )

        let jobsVC = UINavigationController(
            rootViewController: JobsViewController()
        )

        let profileVC = UINavigationController(
            rootViewController: ProfileViewController()
        )

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
        tabBar.tintColor = .systemGreen
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .systemBackground
    }
}
