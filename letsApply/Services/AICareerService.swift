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
        cvText: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success(makeCoverLetter(
            userProfile: userProfile,
            job: job,
            cvText: cvText
        )))
    }

    func tailorCV(
        userProfile: UserProfile,
        job: Job,
        cvText: String? = nil,
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

    func generateApplicationEmail(
        userProfile: UserProfile,
        job: Job,
        coverLetter: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success(makeApplicationEmail(
            userProfile: userProfile,
            job: job,
            coverLetter: coverLetter
        )))
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
        let requiredKeywords = uniqueValues(
            job.requirements + job.qualifications + job.responsibilities
        )
        let profileEvidence = profileEvidenceText(for: userProfile)
        let matchedKeywords = requiredKeywords.filter {
            phrase($0, isSupportedBy: profileEvidence)
        }
        let missingSkills = requiredKeywords.filter {
            !phrase($0, isSupportedBy: profileEvidence)
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
        \(job.title)
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

        let coverLetterText = makeCoverLetter(
            userProfile: userProfile,
            job: job,
            cvText: nil
        )

        let emailSubject = "Application for \(job.title) - \(userProfile.name)"
        let emailBody = makeApplicationEmail(
            userProfile: userProfile,
            job: job,
            coverLetter: coverLetterText
        )

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

        if userProfile.cvUrl == nil && AppFeatures.firebaseStorageUploadsEnabled {
            recommendations.insert("Upload your CV before submitting for a stronger application.", at: 0)
        } else if userProfile.cvUrl == nil {
            recommendations.insert("This package uses your profile CV draft while PDF uploads are paused.", at: 0)
        }

        if !missingSkills.isEmpty {
            recommendations.append("If accurate, add evidence for: \(missingSkills.prefix(4).joined(separator: ", ")).")
        }

        if job.application.applicationEmail.isEmpty {
            recommendations.append("This job does not list a recruiter email, so the app can submit and track internally.")
        }

        return recommendations
    }

    private func makeCoverLetter(
        userProfile: UserProfile,
        job: Job,
        cvText: String?
    ) -> String {
        let supportedSkills = userProfile.skills.filter {
            phrase($0, isSupportedBy: jobEvidenceText(for: job))
        }
        let focusSkills = Array((supportedSkills.isEmpty ? userProfile.skills : supportedSkills).prefix(4))
        let skillText = naturalList(focusSkills)
        let summary = firstSentence(
            from: userProfile.professionalSummary,
            fallback: "My professional background has prepared me to contribute with sound judgement, adaptability, and a strong commitment to quality."
        )
        let rolePriority = firstSentence(
            from: job.responsibilities.first
                ?? job.requirements.first
                ?? job.description,
            fallback: "deliver the core responsibilities of the position"
        )

        let opening = """
        I am writing to apply for the \(job.title) position at \(job.companyName). \(summary)
        """

        let experienceParagraph = experienceEvidence(
            for: userProfile,
            fallbackSkills: skillText,
            job: job
        )

        let educationParagraph = educationEvidence(
            for: userProfile,
            job: job,
            cvText: cvText
        )

        let alignmentText: String
        if skillText.isEmpty {
            alignmentText = "The position’s emphasis on \(embeddedPhrase(rolePriority)) closely matches the direction of my experience and the standard of work I aim to deliver."
        } else {
            alignmentText = "The position’s emphasis on \(embeddedPhrase(rolePriority)) aligns closely with my strengths in \(skillText). I would bring these capabilities to the role with careful execution, clear communication, and respect for the organisation’s objectives."
        }

        let credentialsAndFit = [educationParagraph, alignmentText]
            .map(cleanParagraph)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let motivation = "I am drawn to the opportunity to contribute within \(job.companyName) and would welcome a conversation about how my experience can support your priorities in the \(job.title) role."

        return [
            "Dear Hiring Manager,",
            cleanParagraph(opening),
            cleanParagraph(experienceParagraph),
            credentialsAndFit,
            cleanParagraph(motivation),
            "Thank you for considering my application.",
            "Kind regards,\n\(userProfile.name)"
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    private func experienceEvidence(
        for profile: UserProfile,
        fallbackSkills: String,
        job: Job
    ) -> String {
        if let experience = bestExperience(for: profile, job: job) {
            let role = cleanInline(experience.jobTitle)
            let company = cleanInline(experience.company)
            let responsibility = firstSentence(
                from: experience.responsibilities.first ?? "",
                fallback: ""
            )
            let roleContext = [role, company]
                .filter { !$0.isEmpty }
                .joined(separator: " at ")

            if !responsibility.isEmpty {
                return "In my experience \(roleContext.isEmpty ? "" : "as \(roleContext), ")my responsibilities have included \(embeddedPhrase(responsibility)). This has strengthened my ability to assess priorities, work responsibly with others, and carry work through to a professional standard."
            }

            if !roleContext.isEmpty {
                return "My experience as \(roleContext) has developed the practical judgement, accountability, and collaborative approach required to succeed as a \(job.title)."
            }
        }

        let legacyExperience = firstSentence(from: profile.experience, fallback: "")
        if !legacyExperience.isEmpty {
            return "My experience includes \(embeddedPhrase(legacyExperience)). This foundation would allow me to approach the role with practical understanding and a strong sense of responsibility."
        }

        if !fallbackSkills.isEmpty {
            return "My capabilities in \(fallbackSkills) give me a relevant foundation for the \(job.title) position, supported by a willingness to learn quickly and contribute reliably."
        }

        return "I would approach the \(job.title) position with professionalism, thoughtful problem-solving, and a strong commitment to learning the organisation’s needs."
    }

    private func bestExperience(
        for profile: UserProfile,
        job: Job
    ) -> CVWorkExperience? {
        let jobTokens = Set(meaningfulTokens(from: jobEvidenceText(for: job)))
        return profile.resolvedWorkExperiences.max { left, right in
            experienceScore(left, jobTokens: jobTokens)
                < experienceScore(right, jobTokens: jobTokens)
        }
    }

    private func experienceScore(
        _ experience: CVWorkExperience,
        jobTokens: Set<String>
    ) -> Int {
        let evidence = (
            [experience.jobTitle, experience.company]
            + experience.responsibilities
        )
        .joined(separator: " ")

        return meaningfulTokens(from: evidence)
            .filter { jobTokens.contains($0) }
            .count
    }

    private func educationEvidence(
        for profile: UserProfile,
        job: Job,
        cvText: String?
    ) -> String {
        let jobEvidence = jobEvidenceText(for: job)
        let matchingEducation = profile.resolvedEducationEntries.first {
            phrase(
                "\($0.qualification) \($0.fieldOfStudy) \($0.details)",
                isSupportedBy: jobEvidence
            )
        }
        let education = matchingEducation ?? profile.resolvedEducationEntries.first
        let matchingCertificates = profile.resolvedQualificationEntries.filter {
            phrase("\($0.title) \($0.issuer)", isSupportedBy: jobEvidence)
        }
        let certificates = matchingCertificates.isEmpty
            ? Array(profile.resolvedQualificationEntries.prefix(2))
            : Array(matchingCertificates.prefix(2))

        var evidenceParts: [String] = []
        if let education = education {
            let qualification = cleanInline(education.qualification)
            let fieldOfStudy = cleanInline(education.fieldOfStudy)
            let institution = cleanInline(education.institution)
            var educationText = qualification

            if !fieldOfStudy.isEmpty {
                educationText += educationText.isEmpty
                    ? fieldOfStudy
                    : " in \(fieldOfStudy)"
            }

            if !institution.isEmpty {
                educationText += educationText.isEmpty
                    ? institution
                    : " from \(institution)"
            }

            if !educationText.isEmpty {
                evidenceParts.append(educationText)
            }
        }

        if !certificates.isEmpty {
            evidenceParts.append(
                naturalList(certificates.map {
                    let title = cleanInline($0.title)
                    let issuer = cleanInline($0.issuer)
                    return issuer.isEmpty ? title : "\(title) from \(issuer)"
                })
            )
        }

        if evidenceParts.isEmpty, let cvText = cvText {
            let cvEvidence = firstSentence(from: cvText, fallback: "")
            if !cvEvidence.isEmpty {
                evidenceParts.append(cvEvidence)
            }
        }

        guard !evidenceParts.isEmpty else { return "" }
        return "My preparation for this opportunity is further supported by \(naturalList(evidenceParts)). This foundation complements my practical experience and strengthens my ability to understand the role’s technical and organisational context."
    }

    private func makeApplicationEmail(
        userProfile: UserProfile,
        job: Job,
        coverLetter: String
    ) -> String {
        let hasCoverLetter = !coverLetter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let attachmentText = hasCoverLetter
            ? "my tailored CV and cover letter"
            : "my tailored CV"

        return """
        Dear Hiring Manager,

        Please accept my application for the \(job.title) position at \(job.companyName). I have attached \(attachmentText) for your consideration.

        I would welcome the opportunity to discuss how my experience and capabilities align with the priorities of this role. Thank you for your time and consideration.

        Kind regards,
        \(userProfile.name)
        \(userProfile.phone)
        \(userProfile.email)
        """
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func profileEvidenceText(for profile: UserProfile) -> String {
        let workEvidence = profile.resolvedWorkExperiences.flatMap {
            [$0.jobTitle, $0.company] + $0.responsibilities
        }
        let educationEvidence = profile.resolvedEducationEntries.flatMap {
            [$0.qualification, $0.fieldOfStudy, $0.details]
        }
        let certificateEvidence = profile.resolvedQualificationEntries.flatMap {
            [$0.title, $0.issuer]
        }

        return (
            [profile.jobTitle, profile.professionalSummary, profile.experience, profile.education]
            + profile.skills
            + profile.qualifications
            + workEvidence
            + educationEvidence
            + certificateEvidence
        )
        .joined(separator: " ")
        .lowercased()
    }

    private func jobEvidenceText(for job: Job) -> String {
        (
            [job.title, job.description, job.jobCategory]
            + job.requirements
            + job.qualifications
            + job.responsibilities
        )
        .joined(separator: " ")
        .lowercased()
    }

    private func phrase(_ value: String, isSupportedBy evidence: String) -> Bool {
        let phraseTokens = meaningfulTokens(from: value)
        guard !phraseTokens.isEmpty else { return false }

        let evidenceTokens = Set(meaningfulTokens(from: evidence))
        let matchCount = phraseTokens.filter { evidenceTokens.contains($0) }.count
        let requiredMatches = phraseTokens.count == 1 ? 1 : min(2, phraseTokens.count)
        return matchCount >= requiredMatches
    }

    private func meaningfulTokens(from value: String) -> [String] {
        let ignoredWords: Set<String> = [
            "and", "the", "with", "for", "from", "that", "this", "your",
            "you", "our", "are", "will", "have", "has", "job", "role"
        ]

        return value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !ignoredWords.contains($0) }
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter {
            let key = $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func firstSentence(from value: String, fallback: String) -> String {
        let cleaned = cleanInline(value)
        guard !cleaned.isEmpty else { return fallback }

        let sentence = cleaned
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? cleaned

        let shortened = sentence.count > 260
            ? String(sentence.prefix(257)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
            : sentence

        return sentenceWithPunctuation(shortened)
    }

    private func cleanParagraph(_ value: String) -> String {
        value
            .components(separatedBy: .newlines)
            .map(cleanInline)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func cleanInline(_ value: String) -> String {
        value
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "▪", with: "")
            .replacingOccurrences(of: "◆", with: "")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: "-*")
            ))
    }

    private func sentenceWithPunctuation(_ value: String) -> String {
        guard let lastCharacter = value.last else { return value }
        return ".!?".contains(lastCharacter) ? value : "\(value)."
    }

    private func lowercased(_ value: String) -> String {
        guard let firstCharacter = value.first else { return value }
        return firstCharacter.lowercased() + value.dropFirst()
    }

    private func embeddedPhrase(_ value: String) -> String {
        lowercased(
            value.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
            )
        )
    }

    private func naturalList(_ values: [String]) -> String {
        let cleaned = values.map(cleanInline).filter { !$0.isEmpty }
        guard let last = cleaned.last else { return "" }

        if cleaned.count == 1 {
            return last
        }

        return "\(cleaned.dropLast().joined(separator: ", ")) and \(last)"
    }
}
