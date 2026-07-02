//
//  letsApplyTests.swift
//  letsApplyTests
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import Testing
@testable import letsApply

struct letsApplyTests {

    @Test func detectsApprovedGreenhouseSource() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://boards.greenhouse.io/openai"
        )

        guard case .greenhouse(let token) = provider else {
            Issue.record("Expected a Greenhouse source")
            return
        }
        #expect(token == "openai")
    }

    @Test func detectsApprovedLeverSource() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://jobs.lever.co/example"
        )

        guard case .lever(let site, let isEuropean) = provider else {
            Issue.record("Expected a Lever source")
            return
        }
        #expect(site == "example")
        #expect(isEuropean == false)
    }

    @Test func marksLinkedInAsRestrictedPartner() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://www.linkedin.com/jobs/view/123"
        )

        guard case .restrictedPartner(let name) = provider else {
            Issue.record("Expected a restricted partner source")
            return
        }
        #expect(name == "LinkedIn")
    }

    @Test func z83RequiresLegalReviewAndSignature() {
        let profile = Z83ApplicationProfile(fullName: "Example Candidate")

        #expect(profile.isComplete == false)
        #expect(profile.missingRequiredFields.contains("Signature"))
        #expect(profile.missingRequiredFields.contains("Declaration acceptance"))
    }

    @Test func higherEducationVacancyUsesOfficialRecruitmentWebsite() {
        let job = makeJob(
            companyName: "Department of Higher Education and Training",
            applicationMethod: "governmentManual",
            applicationURL: "",
            requiresZ83: true
        )

        #expect(job.applicationMethod == .governmentWebsite)
        #expect(job.applicationRoute == .externalPortal)
        #expect(job.resolvedApplicationURLString == "https://z83.ngnscan.co.za/login")
        #expect(job.applicationWebsiteName == "DHET e-Recruitment")
    }

    @Test func coverLetterUsesRelevantEvidenceWithoutRawSkillDump() {
        let profile = UserProfile(
            uid: "candidate-1",
            name: "Reuben Kuse",
            email: "reuben@example.com",
            location: "Durban",
            professionalSummary: "Monitoring and evaluation practitioner with experience in academic governance.",
            jobTitle: "Assessment Lead",
            skills: [
                "MS Office",
                "Advanced Research Skills",
                "Communication Skills (verbal and written)"
            ],
            qualifications: ["Postgraduate qualification"],
            experience: "Assessment and academic governance experience",
            education: "Programme Evaluation",
            workExperiences: [
                CVWorkExperience(
                    jobTitle: "Assessment Lead",
                    company: "Regent Business School",
                    responsibilities: [
                        "Lead and manage the full academic assessment lifecycle",
                        "Contribute to academic governance frameworks"
                    ]
                )
            ],
            educationEntries: [
                CVEducationEntry(
                    qualification: "MPhil",
                    institution: "University of Cape Town",
                    fieldOfStudy: "Programme Evaluation"
                )
            ]
        )
        let job = makeJob(
            title: "Deputy Director: Initiation and Evaluation",
            companyName: "Department of Higher Education and Training",
            requirements: ["Advanced research and analytical capability"],
            responsibilities: [
                "Coordinate programme monitoring and evaluation",
                "Prepare evidence-based reports for stakeholders"
            ],
            applicationMethod: "governmentWebsite",
            applicationURL: "https://z83.ngnscan.co.za/login",
            requiresZ83: true
        )

        var generatedLetter = ""
        AICareerService().generateCoverLetter(userProfile: profile, job: job) { result in
            if case .success(let letter) = result {
                generatedLetter = letter
            }
        }

        #expect(generatedLetter.contains("Dear Selection Committee,"))
        #expect(generatedLetter.contains("As Assessment Lead at Regent Business School"))
        #expect(generatedLetter.contains("University of Cape Town"))
        #expect(generatedLetter.contains("Yours faithfully"))
        #expect(generatedLetter.contains("•") == false)
        #expect(generatedLetter.contains("❖") == false)
        #expect(generatedLetter.contains("I handled") == false)
        #expect(generatedLetter.contains("MS Office, Advanced Research Skills") == false)
    }

    private func makeJob(
        title: String = "Deputy Director",
        companyName: String,
        requirements: [String] = ["Relevant qualification"],
        responsibilities: [String] = ["Coordinate programme delivery"],
        applicationMethod: String,
        applicationURL: String,
        requiresZ83: Bool
    ) -> Job {
        Job(
            id: "job-1",
            title: title,
            companyName: companyName,
            companyImageName: nil,
            location: Location(
                city: "Pretoria",
                region: "Gauteng",
                country: "South Africa"
            ),
            jobType: "Permanent",
            remote: false,
            description: "Provide programme leadership and evidence-based reporting.",
            qualifications: ["Relevant postgraduate qualification"],
            responsibilities: responsibilities,
            requirements: requirements,
            experience: Experience(
                minYears: 3,
                preferredYears: 5,
                details: "Relevant management experience"
            ),
            compensation: Compensation(
                salaryRange: SalaryRange(
                    min: 900_000,
                    max: 1_100_000,
                    currency: "ZAR",
                    period: "annum"
                ),
                benefits: []
            ),
            application: JobApplicationInfo(
                deadline: "31 July 2026",
                applicationUrl: applicationURL,
                applicationEmail: "",
                contactPhone: "",
                method: applicationMethod,
                applicationInstructions: "Complete the online application.",
                requiresZ83: requiresZ83,
                referenceNumber: "DHET/01/2026"
            ),
            jobCategory: "Public Service",
            postingDate: "2026-07-01",
            visibility: Visibility(featured: false, promoted: false),
            promoted: nil,
            sourceName: "DPSA",
            sourceUrl: "https://www.dpsa.gov.za/newsroom/psvc/",
            sourceType: JobSourceType.publicFeed.rawValue,
            verified: true,
            closingDate: "2026-07-31"
        )
    }

}
