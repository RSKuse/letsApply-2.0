//
//  AICareerService.swift
//  letsApply
//

import Foundation

class AICareerService {

    enum CareerTool {
        case coverLetter
        case tailorCV
        case improveCV

        var title: String {
            switch self {
            case .coverLetter:
                return "AI Cover Letter"
            case .tailorCV:
                return "Tailor CV"
            case .improveCV:
                return "Improve CV"
            }
        }
    }

    func generateCoverLetter(
        userProfile: UserProfile,
        job: Job,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let response = """
        AI cover letter integration is ready for \(job.title) at \(job.companyName).

        Next integration step:
        Send the user's profile, CV content, job description, and requirements to the AI API, then return editable text here.
        """
        completion(.success(response))
    }

    func tailorCV(
        userProfile: UserProfile,
        job: Job,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let response = """
        CV tailoring integration is ready for \(job.title).

        Suggested AI output:
        - Missing skills from this job
        - Stronger professional summary
        - Job-specific experience wording
        - Recommended CV sections to move higher
        """
        completion(.success(response))
    }

    func improveCV(
        userProfile: UserProfile,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let response = """
        CV improvement integration is ready.

        Suggested AI output:
        - Clearer achievements
        - Stronger skills grouping
        - Education and experience cleanup
        - Recruiter-friendly wording
        """
        completion(.success(response))
    }

    func prepareAutoApplyPackage(
        userProfile: UserProfile,
        job: Job,
        completion: @escaping (Result<AutoApplyPackage, Error>) -> Void
    ) {
        let requiredKeywords = job.requirements + job.qualifications
        let userKeywords = userProfile.skills + userProfile.qualifications
        let normalizedUserKeywords = Set(userKeywords.map { $0.lowercased() })

        let matchedKeywords = requiredKeywords.filter {
            normalizedUserKeywords.contains($0.lowercased())
        }
        let missingSkills = requiredKeywords.filter {
            !normalizedUserKeywords.contains($0.lowercased())
        }

        let matchScore = calculateMatchScore(
            matchedCount: matchedKeywords.count,
            requiredCount: requiredKeywords.count,
            profileIsComplete: userProfile.isComplete
        )

        let recommendations = makeRecommendations(
            userProfile: userProfile,
            job: job,
            missingSkills: missingSkills
        )

        let tailoredCVText = """
        \(userProfile.name)
        \(userProfile.jobTitle)
        \(userProfile.location)

        Professional Summary
        \(userProfile.professionalSummary.isEmpty ? "Experienced candidate interested in \(job.title) roles." : userProfile.professionalSummary)

        Tailored Focus for \(job.title)
        - Highlight experience related to \(job.jobCategory).
        - Move relevant skills higher: \(matchedKeywords.isEmpty ? userProfile.skills.joined(separator: ", ") : matchedKeywords.joined(separator: ", ")).
        - Add evidence for these requirements where true: \(missingSkills.prefix(4).joined(separator: ", ")).

        Experience
        \(userProfile.experience)

        Education
        \(userProfile.education)
        """

        let coverLetterText = """
        Dear Hiring Team,

        I am applying for the \(job.title) role at \(job.companyName). My background in \(userProfile.jobTitle) and my experience with \(userProfile.skills.prefix(4).joined(separator: ", ")) make this opportunity strongly aligned with my career goals.

        I am particularly interested in this role because it focuses on \(job.jobCategory), and I can bring practical experience, professionalism, and a strong commitment to delivering quality work.

        Thank you for considering my application.

        Kind regards,
        \(userProfile.name)
        """

        let emailSubject = "Application for \(job.title) - \(userProfile.name)"
        let emailBody = """
        Dear Hiring Team,

        Please find my application for the \(job.title) position at \(job.companyName).

        I have attached my CV and included a cover letter for your consideration. I would welcome the opportunity to discuss how my experience and skills align with this role.

        Kind regards,
        \(userProfile.name)
        """

        let package = AutoApplyPackage(
            matchScore: matchScore,
            matchSummary: "You currently match this job by \(matchScore)%. Review the suggested package before submitting.",
            missingSkills: missingSkills,
            recommendations: recommendations,
            tailoredCVText: tailoredCVText,
            coverLetterText: coverLetterText,
            emailSubject: emailSubject,
            emailBody: emailBody
        )

        completion(.success(package))
    }

    private func calculateMatchScore(matchedCount: Int, requiredCount: Int, profileIsComplete: Bool) -> Int {
        guard requiredCount > 0 else {
            return profileIsComplete ? 72 : 45
        }

        let keywordScore = Double(matchedCount) / Double(requiredCount)
        let completionBoost = profileIsComplete ? 0.20 : 0.0
        let score = Int(((keywordScore * 0.80) + completionBoost) * 100)
        return min(max(score, 25), 96)
    }

    private func makeRecommendations(
        userProfile: UserProfile,
        job: Job,
        missingSkills: [String]
    ) -> [String] {
        var recommendations: [String] = [
            "Review the tailored CV text before attaching it to your application.",
            "Add measurable achievements to your experience section where possible.",
            "Make sure the cover letter still sounds like you before submitting."
        ]

        if userProfile.cvUrl == nil {
            recommendations.insert("Upload your CV before submitting for a stronger application.", at: 0)
        }

        if !missingSkills.isEmpty {
            recommendations.append("If accurate, add evidence for: \(missingSkills.prefix(4).joined(separator: ", ")).")
        }

        if job.application.applicationEmail.isEmpty {
            recommendations.append("This job does not list a recruiter email, so the app can submit and track internally.")
        }

        return recommendations
    }
}
