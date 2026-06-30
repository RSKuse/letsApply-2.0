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
        if debugScreen == "home" {
            return UINavigationController(rootViewController: HomeViewController())
        }
        if debugScreen == "admin-jobs" {
            return UINavigationController(
                rootViewController: AdminJobsViewController(isDebugMode: true)
            )
        }
        if debugScreen == "admin-editor" {
            return UINavigationController(
                rootViewController: AdminJobEditorViewController(isDebugMode: true)
            )
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
        if debugScreen == "auto-apply" {
            let profile = UserProfile(
                uid: "debug-user",
                name: "Reuben Kuse",
                email: "reuben@example.com",
                phone: "066 000 0000",
                location: "Durban, South Africa",
                professionalSummary: "Analytical researcher and digital systems specialist with experience in programme evaluation, governance, stakeholder engagement, and institutional reporting.",
                jobTitle: "Research and Evaluation Specialist",
                skills: ["Research", "Programme Evaluation", "Report Writing", "Stakeholder Engagement", "Power BI"],
                qualifications: ["AWS Cloud Practitioner"],
                workExperiences: [
                    CVWorkExperience(
                        jobTitle: "Assessment Lead",
                        company: "Regent Business School",
                        location: "Durban",
                        startDate: "2023",
                        endDate: "Present",
                        responsibilities: [
                            "Lead governance and quality assurance processes.",
                            "Produce analytical reports and coordinate multidisciplinary stakeholders."
                        ]
                    )
                ],
                educationEntries: [
                    CVEducationEntry(
                        qualification: "MPhil",
                        institution: "University of Cape Town",
                        fieldOfStudy: "Programme Evaluation",
                        endYear: "In progress"
                    )
                ],
                qualificationEntries: [
                    CVQualificationEntry(
                        title: "Postgraduate Diploma in Public Management",
                        issuer: "University of the Witwatersrand",
                        year: "2022"
                    )
                ]
            )
            let job = Job(
                id: "debug-government-job",
                title: "Senior Researcher",
                companyName: "Department of Public Service",
                companyImageName: nil,
                location: Location(city: "Pretoria", region: "Gauteng", country: "South Africa"),
                jobType: "Permanent",
                remote: false,
                description: "Conduct policy research, evaluate public programmes, produce evidence-based reports, and coordinate stakeholder engagements. Applications must include a completed Z83 form.",
                qualifications: ["Postgraduate qualification", "Research methodology"],
                responsibilities: [
                    "Conduct qualitative and quantitative research.",
                    "Prepare policy briefs and analytical reports.",
                    "Coordinate engagements with public-sector stakeholders."
                ],
                requirements: ["Programme evaluation", "Policy analysis", "Report writing"],
                experience: Experience(minYears: 5, preferredYears: 7, details: "Public-sector research experience preferred."),
                compensation: Compensation(
                    salaryRange: SalaryRange(
                        min: 657_477,
                        max: 989_678,
                        currency: "ZAR",
                        period: "annum"
                    ),
                    benefits: ["Government employee benefits"]
                ),
                application: JobApplicationInfo(
                    deadline: "19 July 2026",
                    applicationUrl: "",
                    applicationEmail: "applications@example.gov.za",
                    contactPhone: "",
                    method: "z83",
                    formName: "Z83 Application for Employment",
                    requiredForms: ["Z83 form"],
                    requiredDocuments: ["Certified ID copy", "Certified qualifications"],
                    requiresCoverLetter: true,
                    requiresCV: true,
                    requiresZ83: true,
                    requiresCertifiedDocuments: true
                ),
                jobCategory: "Government and Research",
                postingDate: "2026-06-28",
                visibility: Visibility(featured: true, promoted: true),
                promoted: ["Verified"],
                sourceName: "DPSA Public Service Vacancy Circular",
                sourceUrl: "https://www.dpsa.gov.za/newsroom/psvc/",
                sourceType: JobSourceType.government.rawValue,
                dateImported: "2026-06-28",
                verified: true
            )
            return UINavigationController(
                rootViewController: AutoApplyAssistantViewController(
                    job: job,
                    userProfile: profile
                )
            )
        }
        #endif

        return SplashViewController()
    }
}
