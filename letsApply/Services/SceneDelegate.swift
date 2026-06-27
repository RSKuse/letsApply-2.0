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
        let debugScreen = ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_SCREEN"]
        if debugScreen == "cv-studio" {
            return UINavigationController(rootViewController: CVBuilderViewController())
        }
        if debugScreen == "profile" {
            let profileViewController = ProfileViewController()
            profileViewController.debugProfile = UserProfile(
                name: "Reuben Kuse",
                email: "reuben@example.com",
                phone: "066 000 0000",
                location: "Durban, South Africa",
                professionalSummary: "Analytical researcher and digital systems specialist focused on evidence, public impact, and clear decision-making.",
                jobTitle: "Software Developer",
                skills: ["Swift", "Research", "Monitoring and Evaluation"],
                qualifications: ["AWS Cloud Practitioner"],
                workExperiences: [
                    CVWorkExperience(
                        jobTitle: "Research and Technology Specialist",
                        company: "Example Organisation",
                        location: "Durban",
                        startDate: "2023",
                        endDate: "Present",
                        responsibilities: ["Turned complex evidence into practical recommendations."]
                    )
                ],
                educationEntries: [
                    CVEducationEntry(
                        qualification: "Master of Management",
                        institution: "University of the Witwatersrand",
                        fieldOfStudy: "Monitoring and Evaluation",
                        endYear: "2022"
                    )
                ],
                qualificationEntries: [
                    CVQualificationEntry(
                        title: "AWS Cloud Practitioner",
                        issuer: "Amazon Web Services",
                        year: "2025"
                    )
                ]
            )
            return UINavigationController(rootViewController: profileViewController)
        }
        #endif

        return SplashViewController()
    }
}
