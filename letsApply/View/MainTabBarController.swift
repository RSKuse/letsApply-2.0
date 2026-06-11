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
            rootViewController: JobListViewController()
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
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground
    }
}

/*class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureTabBarAppearance()
    }

    private func setupTabs() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        let jobsVC = UINavigationController(rootViewController: JobListViewController())
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        let cvVC = UINavigationController(rootViewController: CVBuilderViewController())

        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        jobsVC.tabBarItem = UITabBarItem(title: "Jobs", image: UIImage(systemName: "briefcase.fill"), tag: 1)
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 2)
        cvVC.tabBarItem = UITabBarItem(title: "CV", image: UIImage(systemName: "doc.text.fill"), tag: 3)

        viewControllers = [homeVC, jobsVC, profileVC, cvVC]
    }

    private func configureTabBarAppearance() {
        tabBar.tintColor = .systemGreen
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .white
    }
}*/
