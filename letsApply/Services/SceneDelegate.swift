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
        if debugScreen == "jobs" {
            return MainTabBarController(initialSelectedIndex: 1)
        }
        if debugScreen == "job-details" {
            return UINavigationController(
                rootViewController: JobDetailsViewController(
                    job: Self.debugGovernmentJob(),
                    isPreviewMode: true
                )
            )
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
        if debugScreen == "admin-import" {
            return UINavigationController(
                rootViewController: AdminSourceImportViewController(isDebugMode: true)
            )
        }
        if debugScreen == "z83" {
            let profile = Self.debugGovernmentProfile()
            let job = FirestoreService.sampleJobs().first(where: \.requiresGovernmentFlow)
                ?? Self.debugGovernmentJob()
            try? Z83ProfileStore().save(
                Self.debugCompletedZ83Profile(name: profile.name),
                userId: profile.uid
            )
            return UINavigationController(
                rootViewController: Z83EditorViewController(
                    job: job,
                    userProfile: profile
                )
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
            if ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_Z83"] == "1" {
                try? Z83ProfileStore().save(
                    Self.debugCompletedZ83Profile(name: profile.name),
                    userId: profile.uid
                )
            }
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

private extension SceneDelegate {

    static func debugGovernmentProfile() -> UserProfile {
        UserProfile(
            uid: "debug-user",
            name: "Reuben Kuse",
            email: "reuben@example.com",
            phone: "066 000 0000",
            location: "Durban, South Africa",
            professionalSummary: "Research and evaluation specialist.",
            jobTitle: "Research Specialist",
            skills: ["Research", "Policy analysis", "Report writing"],
            qualifications: ["AWS Cloud Practitioner"],
            workExperiences: [
                CVWorkExperience(
                    jobTitle: "Assessment Lead",
                    company: "Regent Business School",
                    location: "Durban",
                    startDate: "01/2023",
                    endDate: "Present",
                    responsibilities: ["Led assessment governance and reporting."]
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
            references: [
                CVReference(
                    name: "Example Referee",
                    jobTitle: "Academic Manager",
                    company: "Example Institution",
                    relationship: "Former manager",
                    email: "referee@example.com",
                    phone: "011 000 0000"
                )
            ]
        )
    }

    static func debugGovernmentJob() -> Job {
        Job(
            id: "debug-z83-job",
            title: "Senior Researcher",
            companyName: "Department of Public Service",
            companyImageName: nil,
            location: Location(city: "Pretoria", region: "Gauteng", country: "South Africa"),
            jobType: "Permanent",
            remote: false,
            description: "Government research vacancy requiring a Z83.",
            qualifications: ["Relevant postgraduate qualification"],
            responsibilities: ["Conduct research and prepare reports"],
            requirements: ["Research", "Report writing"],
            experience: Experience(minYears: 3, preferredYears: 5, details: ""),
            compensation: Compensation(
                salaryRange: SalaryRange(
                    min: 657_477,
                    max: 989_678,
                    currency: "ZAR",
                    period: "annum"
                ),
                benefits: []
            ),
            application: JobApplicationInfo(
                deadline: "31 July 2026",
                applicationUrl: "",
                applicationEmail: "applications@example.gov.za",
                contactPhone: "",
                method: "governmentEmail",
                formName: "Z83 Application for Employment",
                requiredForms: ["Z83 form"],
                requiredDocuments: ["CV"],
                applicationInstructions: "Email the completed and signed Z83 form and detailed CV to applications@example.gov.za. Quote REF/2026/001 in the subject line.",
                requiresCoverLetter: true,
                requiresCV: true,
                requiresZ83: true,
                referenceNumber: "REF/2026/001"
            ),
            jobCategory: "Public Service",
            postingDate: "2026-07-01",
            visibility: Visibility(featured: true, promoted: false),
            promoted: nil,
            sourceName: "DPSA",
            sourceUrl: "https://www.dpsa.gov.za/newsroom/psvc/",
            sourceType: JobSourceType.government.rawValue,
            verified: true
        )
    }

    static func debugCompletedZ83Profile(name: String) -> Z83ApplicationProfile {
        let stroke = SignatureStroke(points: [
            SignaturePoint(CGPoint(x: 0.08, y: 0.70)),
            SignaturePoint(CGPoint(x: 0.25, y: 0.30)),
            SignaturePoint(CGPoint(x: 0.42, y: 0.68)),
            SignaturePoint(CGPoint(x: 0.62, y: 0.28)),
            SignaturePoint(CGPoint(x: 0.88, y: 0.62))
        ])
        return Z83ApplicationProfile(
            fullName: name,
            dateOfBirth: "01/01/1990",
            identityNumber: "9001015009087",
            race: "African",
            gender: "Male",
            hasDisability: .no,
            isSouthAfricanCitizen: .yes,
            hasValidWorkPermit: .no,
            hasCriminalConviction: .no,
            hasPendingCriminalCase: .no,
            dismissedForPublicServiceMisconduct: .no,
            hasPendingDisciplinaryCase: .no,
            resignedPendingDisciplinaryProceedings: .no,
            dischargedForIllHealth: .no,
            conductsBusinessWithState: .no,
            willRelinquishBusinessInterests: .yes,
            privateSectorYears: "5",
            publicSectorYears: "0",
            preferredLanguage: "English",
            communicationMethod: "Email",
            availability: "One month notice",
            previousPublicServiceRestriction: .no,
            signatureStrokes: [stroke],
            declarationAccepted: true
        )
    }
}
