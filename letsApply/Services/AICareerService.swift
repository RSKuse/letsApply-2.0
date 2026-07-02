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

        let tailoredCVText = makeCVPreview(
            userProfile: userProfile,
            job: job
        )

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
            matchSummary: "Your profile currently matches \(matchScore)% of the vacancy evidence we can verify. Review the documents before continuing.",
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
            "Review the CV preview before attaching it to your application.",
            "Add measurable achievements to your experience section where possible.",
            "Read the cover letter aloud and edit any wording that does not sound like you."
        ]

        if userProfile.cvUrl == nil && AppFeatures.firebaseStorageUploadsEnabled {
            recommendations.insert("Upload your CV before submitting for a stronger application.", at: 0)
        } else if userProfile.cvUrl == nil {
            recommendations.insert("Your profile will be used to create the CV attachment while PDF uploads are paused.", at: 0)
        }

        if !missingSkills.isEmpty {
            recommendations.append("If accurate, add evidence for: \(missingSkills.prefix(4).joined(separator: ", ")).")
        }

        if job.applicationRoute == .inApp {
            recommendations.append("This vacancy accepts a direct Let’s Apply submission and will be recorded in your tracker.")
        } else if job.applicationRoute == .externalPortal {
            recommendations.append("The employer’s website requires the final submission, so keep the prepared documents ready to attach.")
        }

        return recommendations
    }

    private func makeCoverLetter(
        userProfile: UserProfile,
        job: Job,
        cvText: String?
    ) -> String {
        let priorities = jobPriorityPhrases(for: job)
        let strengths = relevantStrengths(for: userProfile, job: job)
        let priorityText = naturalList(Array(priorities.prefix(2)))
        let strengthText = naturalList(strengths)
        let reference = cleanInline(job.application.referenceNumber)
        let subjectReference = reference.isEmpty ? "" : " (REFERENCE: \(reference))"
        let salutation = job.requiresGovernmentFlow
            ? "Dear Selection Committee,"
            : "Dear Hiring Manager,"
        let subject = "APPLICATION FOR THE POSITION OF \(job.title.uppercased())\(subjectReference)"

        var opening = "I wish to apply for the \(job.title) position at \(job.companyName)."
        if !strengthText.isEmpty {
            opening += " Across my professional experience, I have developed \(strengthText), which align closely with the capabilities this appointment requires."
        } else {
            opening += " My professional experience has prepared me to approach this opportunity with sound judgement, accountability, and careful attention to the quality of my work."
        }

        var motivation = ""
        if !priorityText.isEmpty {
            motivation = "What interests me most about this opportunity is its focus on \(priorityText). These responsibilities call for someone who can connect analysis with practical delivery, work constructively with stakeholders, and maintain a clear line of accountability from planning through to reporting."
        }

        let experienceParagraphs = relevantExperienceParagraphs(
            for: userProfile,
            strengths: strengths,
            job: job
        )
        let educationParagraph = educationEvidence(for: userProfile, job: job)

        let closing: String
        if let priority = priorities.first, !priority.isEmpty {
            closing = "I would value the opportunity to contribute to \(job.companyName) and support its work in \(embeddedPhrase(priority)). I am confident that my experience, considered approach, and commitment to high professional standards would enable me to make a meaningful contribution in the \(job.title) role. Thank you for considering my application. I would welcome the opportunity to discuss my suitability with the selection panel."
        } else {
            closing = "I would value the opportunity to contribute to \(job.companyName) as \(job.title). Thank you for considering my application. I would welcome the opportunity to discuss how my experience and approach could support the organisation’s priorities."
        }

        return (
            [salutation, subject, opening, motivation]
            + experienceParagraphs
            + [educationParagraph, closing, "Yours faithfully,\n\(userProfile.name)"]
        )
        .filter { !$0.isEmpty }
        .map(cleanParagraphPreservingLineBreaks)
        .joined(separator: "\n\n")
    }

    private func relevantExperienceParagraphs(
        for profile: UserProfile,
        strengths: [String],
        job: Job
    ) -> [String] {
        let jobTokens = Set(meaningfulTokens(from: jobEvidenceText(for: job)))
        let rankedExperiences = profile.resolvedWorkExperiences
            .enumerated()
            .sorted { left, right in
                let leftScore = experienceScore(left.element, jobTokens: jobTokens)
                let rightScore = experienceScore(right.element, jobTokens: jobTokens)
                return leftScore == rightScore
                    ? left.offset < right.offset
                    : leftScore > rightScore
            }
            .map { $0.element }

        let paragraphs = rankedExperiences.prefix(2).compactMap { experience -> String? in
            let role = cleanInline(experience.jobTitle)
            let company = cleanInline(experience.company)
            let roleContext = [role, company]
                .filter { !$0.isEmpty }
                .joined(separator: " at ")
            guard !roleContext.isEmpty else { return nil }

            let responsibilities = bestResponsibilities(
                from: experience,
                for: job
            )

            if responsibilities.isEmpty {
                return "My experience as \(roleContext) has strengthened my professional judgement, my ability to work responsibly with others, and my accountability for delivering work to a high standard."
            }

            var paragraph = "As \(roleContext), \(lowercasedFirstPersonSentence(responsibilities[0]))"
            if responsibilities.count > 1 {
                paragraph += " \(responsibilities[1])"
            }
            return paragraph
        }

        if !paragraphs.isEmpty {
            return paragraphs
        }

        let strengthText = naturalList(strengths)
        return strengthText.isEmpty
            ? []
            : ["My professional experience has developed \(strengthText). I would apply these capabilities with careful judgement and dependable follow-through in the \(job.title) position."]
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
        job: Job
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
        let certificates = Array(matchingCertificates.prefix(1))

        var evidenceParts: [String] = []
        if let education = education {
            let qualification = cleanInline(education.qualification)
            let fieldOfStudy = cleanInline(education.fieldOfStudy)
            let institution = cleanInline(education.institution)
            var educationText = qualification

            if !fieldOfStudy.isEmpty,
               !qualification.lowercased().contains(fieldOfStudy.lowercased()) {
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

        guard !evidenceParts.isEmpty else { return "" }

        if let priority = jobPriorityPhrases(for: job).first, !priority.isEmpty {
            return "My academic preparation includes \(naturalList(evidenceParts)). This foundation complements my practical experience and supports the analytical depth required for \(embeddedPhrase(priority))."
        }

        return "My academic preparation includes \(naturalList(evidenceParts)). This foundation complements my practical experience and supports work requiring careful analysis, sound judgement, and clear communication."
    }

    private func makeCVPreview(
        userProfile: UserProfile,
        job: Job
    ) -> String {
        var sections: [String] = [
            [
                cleanInline(userProfile.name),
                cleanInline(job.title),
                cleanInline(userProfile.location)
            ]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        ]

        let summary = cleanParagraph(userProfile.professionalSummary)
        if !summary.isEmpty {
            sections.append("PROFESSIONAL PROFILE\n\(summary)")
        }

        let strengths = relevantStrengths(for: userProfile, job: job)
        if !strengths.isEmpty {
            sections.append("RELEVANT STRENGTHS\n\(naturalList(strengths))")
        }

        let experienceSections = userProfile.resolvedWorkExperiences.prefix(3).compactMap { experience -> String? in
            let heading = [cleanInline(experience.jobTitle), cleanInline(experience.company)]
                .filter { !$0.isEmpty }
                .joined(separator: " at ")
            let responsibilities = experience.responsibilities
                .map { sentenceWithPunctuation(cleanInline($0)) }
                .filter { !$0.isEmpty }
                .prefix(3)
                .joined(separator: " ")
            let content = [heading, responsibilities]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            return content.isEmpty ? nil : content
        }
        if !experienceSections.isEmpty {
            sections.append("EXPERIENCE\n\(experienceSections.joined(separator: "\n\n"))")
        }

        let educationSections = userProfile.resolvedEducationEntries.prefix(3).compactMap { entry -> String? in
            let qualification = [cleanInline(entry.qualification), cleanInline(entry.fieldOfStudy)]
                .filter { !$0.isEmpty }
                .joined(separator: " — ")
            let details = [qualification, cleanInline(entry.institution), cleanInline(entry.dateRange)]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            return details.isEmpty ? nil : details
        }
        if !educationSections.isEmpty {
            sections.append("EDUCATION\n\(educationSections.joined(separator: "\n"))")
        }

        let certificates = userProfile.resolvedQualificationEntries.prefix(4).compactMap { entry -> String? in
            let details = [cleanInline(entry.title), cleanInline(entry.issuer), cleanInline(entry.year)]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            return details.isEmpty ? nil : details
        }
        if !certificates.isEmpty {
            sections.append("CERTIFICATES ACQUIRED\n\(certificates.joined(separator: "\n"))")
        }

        let referenceText = userProfile.references.isEmpty
            ? "Available on request"
            : "\(userProfile.references.count) references included in the generated CV"
        sections.append("REFERENCES\n\(referenceText)")

        return sections.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    private func jobPriorityPhrases(for job: Job) -> [String] {
        let source = job.responsibilities.isEmpty
            ? [job.description]
            : job.responsibilities

        return uniqueValues(
            source
                .map(actionObjectPhrase)
                .filter { !$0.isEmpty && $0.count <= 140 }
        )
    }

    private func bestResponsibilities(
        from experience: CVWorkExperience,
        for job: Job
    ) -> [String] {
        let jobTokens = Set(meaningfulTokens(from: jobEvidenceText(for: job)))
        let ranked = experience.responsibilities.enumerated().sorted { left, right in
            let leftScore = meaningfulTokens(from: left.element)
                .filter { jobTokens.contains($0) }
                .count
            let rightScore = meaningfulTokens(from: right.element)
                .filter { jobTokens.contains($0) }
                .count

            return leftScore == rightScore
                ? left.offset < right.offset
                : leftScore > rightScore
        }

        return uniqueValues(
            ranked
                .map { firstPersonEvidenceSentence($0.element) }
                .filter { !$0.isEmpty && $0.count <= 160 }
        )
        .prefix(2)
        .map { $0 }
    }

    private func firstPersonEvidenceSentence(_ value: String) -> String {
        let cleaned = cleanInline(value)
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !cleaned.isEmpty else { return "" }

        let clauses = cleaned.components(separatedBy: " and ")
        let verbForms: [(present: String, past: String)] = [
            ("advise ", "advised "),
            ("analyse ", "analysed "),
            ("analyze ", "analyzed "),
            ("assist ", "assisted "),
            ("chair ", "chaired "),
            ("compile ", "compiled "),
            ("contribute ", "contributed "),
            ("conduct ", "conducted "),
            ("coordinate ", "coordinated "),
            ("create ", "created "),
            ("deliver ", "delivered "),
            ("design ", "designed "),
            ("develop ", "developed "),
            ("ensure ", "ensured "),
            ("evaluate ", "evaluated "),
            ("facilitate ", "facilitated "),
            ("implement ", "implemented "),
            ("introduce ", "introduced "),
            ("lead ", "led "),
            ("maintain ", "maintained "),
            ("manage ", "managed "),
            ("monitor ", "monitored "),
            ("oversee ", "oversaw "),
            ("prepare ", "prepared "),
            ("produce ", "produced "),
            ("provide ", "provided "),
            ("research ", "researched "),
            ("review ", "reviewed "),
            ("supervise ", "supervised "),
            ("support ", "supported "),
            ("write ", "wrote ")
        ]

        let convertedClauses = clauses.enumerated().compactMap { index, clause -> String? in
            let trimmedClause = clause.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasedClause = trimmedClause.lowercased()

            if verbForms.contains(where: {
                let past = $0.past.trimmingCharacters(in: .whitespaces)
                return lowercasedClause == past
                    || lowercasedClause.hasPrefix("\(past) ")
            }) {
                let sentence = lowercased(trimmedClause)
                return index == 0 ? "I \(sentence)" : sentence
            }

            if let verb = verbForms.first(where: {
                lowercasedClause == $0.present.trimmingCharacters(in: .whitespaces)
                    || lowercasedClause.hasPrefix($0.present)
            }) {
                let verbLength = min(
                    trimmedClause.count,
                    verb.present.trimmingCharacters(in: .whitespaces).count
                )
                let remainder = String(trimmedClause.dropFirst(verbLength))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let spacing = remainder.isEmpty ? "" : " "
                return "\(index == 0 ? "I " : "")\(verb.past.trimmingCharacters(in: .whitespaces))\(spacing)\(remainder)"
            }

            if lowercasedClause.hasPrefix("responsible for ") {
                let remainder = String(trimmedClause.dropFirst("responsible for ".count))
                return index == 0
                    ? "I was responsible for \(lowercased(remainder))"
                    : "was responsible for \(lowercased(remainder))"
            }

            return nil
        }

        guard !convertedClauses.isEmpty else { return "" }
        return sentenceWithPunctuation(convertedClauses.joined(separator: " and "))
    }

    private func relevantStrengths(
        for profile: UserProfile,
        job: Job
    ) -> [String] {
        let profileEvidence = profileEvidenceText(for: profile)
        let jobEvidence = jobEvidenceText(for: job)
        var strengths: [String] = []

        func appendStrength(
            _ value: String,
            jobTerms: [String],
            profileTerms: [String]
        ) {
            guard containsAny(jobTerms, in: jobEvidence),
                  containsAny(profileTerms, in: profileEvidence),
                  !strengths.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
            else {
                return
            }
            strengths.append(value)
        }

        appendStrength(
            "monitoring, evaluation, and performance reporting",
            jobTerms: ["monitoring", "evaluation", "performance", "reporting"],
            profileTerms: ["monitoring", "evaluation", "performance", "reporting"]
        )
        appendStrength(
            "policy analysis and governance",
            jobTerms: ["policy", "governance", "prescript", "compliance"],
            profileTerms: ["policy", "governance", "prescript", "compliance"]
        )
        appendStrength(
            "research and evidence synthesis",
            jobTerms: ["research", "evidence", "analysis", "evaluation"],
            profileTerms: ["research", "evidence", "analysis", "evaluation"]
        )
        appendStrength(
            "clear stakeholder communication",
            jobTerms: ["customer", "client", "service", "communication", "stakeholder"],
            profileTerms: ["stakeholder", "communication", "presentation", "support", "engagement"]
        )
        appendStrength(
            "careful analysis and information handling",
            jobTerms: ["accuracy", "accurate", "data", "record", "assessment", "verify", "fraud"],
            profileTerms: ["analysis", "analytical", "research", "assessment", "evidence", "data", "record"]
        )
        appendStrength(
            "structured coordination and delivery",
            jobTerms: ["coordinate", "organise", "manage", "process", "operation", "deadline"],
            profileTerms: ["coordinate", "organise", "manage", "planning", "lifecycle", "programme"]
        )
        appendStrength(
            "working within policy and procedural requirements",
            jobTerms: ["policy", "procedure", "compliance", "regulation", "governance"],
            profileTerms: ["policy", "procedure", "compliance", "governance", "prescript"]
        )
        appendStrength(
            "digital systems proficiency",
            jobTerms: ["system", "digital", "technology", "software", "computer"],
            profileTerms: ["system", "digital", "technology", "software", "programming", "computer"]
        )

        if strengths.isEmpty {
            if containsAny(["stakeholder", "communication", "presentation", "support"], in: profileEvidence) {
                strengths.append("clear stakeholder communication")
            }
            if containsAny(["analysis", "research", "assessment", "evidence", "data"], in: profileEvidence) {
                strengths.append("careful analysis and information handling")
            }
            if containsAny(["coordinate", "manage", "planning", "lifecycle", "programme"], in: profileEvidence) {
                strengths.append("structured coordination and delivery")
            }
        }

        return uniqueValues(strengths).prefix(3).map { $0 }
    }

    private func normalizedSkills(_ values: [String]) -> [String] {
        let separators = CharacterSet(charactersIn: ",;\n\r|•▪◆❖◈●")
        let categoryNames = [
            "skills",
            "languages",
            "programming languages",
            "frameworks",
            "tools",
            "databases",
            "competencies"
        ]

        let items = values.flatMap {
            $0.components(separatedBy: separators)
        }
        .map(cleanInline)
        .map { value -> String in
            guard let colonIndex = value.firstIndex(of: ":") else {
                return value
            }

            let category = String(value[..<colonIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard categoryNames.contains(category) else {
                return value
            }

            return String(value[value.index(after: colonIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { $0.count >= 2 && $0.count <= 70 }

        return uniqueValues(items)
    }

    private func actionObjectPhrase(_ value: String) -> String {
        var phrase = cleanInline(value)
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let colonIndex = phrase.firstIndex(of: ":") {
            let heading = phrase[..<colonIndex]
            let detail = phrase[phrase.index(after: colonIndex)...]
            if heading.split(separator: " ").count <= 4, !detail.isEmpty {
                phrase = String(detail).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let actionPrefixes = [
            "be responsible for ",
            "responsible for ",
            "lead and manage ",
            "manage and coordinate ",
            "coordinate and manage ",
            "design and develop ",
            "develop and implement ",
            "monitor and evaluate ",
            "provide and maintain ",
            "assist with ",
            "responsibilities include ",
            "duties include ",
            "lead ",
            "manage ",
            "coordinate ",
            "support ",
            "maintain ",
            "deliver ",
            "develop ",
            "implement ",
            "conduct ",
            "prepare ",
            "monitor ",
            "evaluate ",
            "ensure ",
            "provide ",
            "oversee "
        ]

        let lowercasedPhrase = phrase.lowercased()
        if let prefix = actionPrefixes.first(where: { lowercasedPhrase.hasPrefix($0) }) {
            phrase = String(phrase.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let incompleteEndings = [
            ", including",
            " including",
            ", such as",
            " such as",
            ", including the",
            " including the"
        ]
        var didRemoveEnding = true
        while didRemoveEnding {
            didRemoveEnding = false
            let lowercasedValue = phrase.lowercased()
            if let ending = incompleteEndings.first(where: { lowercasedValue.hasSuffix($0) }) {
                phrase = String(phrase.dropLast(ending.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                didRemoveEnding = true
            }
        }

        return embeddedPhrase(
            phrase.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
            )
        )
    }

    private func containsAny(_ terms: [String], in value: String) -> Bool {
        terms.contains { value.localizedCaseInsensitiveContains($0) }
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

        let shortened: String
        if sentence.count > 260 {
            let prefix = String(sentence.prefix(260))
            shortened = prefix
                .split(separator: " ")
                .dropLast()
                .joined(separator: " ")
        } else {
            shortened = sentence
        }

        return sentenceWithPunctuation(shortened)
    }

    private func cleanParagraph(_ value: String) -> String {
        value
            .components(separatedBy: .newlines)
            .map(cleanInline)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func cleanParagraphPreservingLineBreaks(_ value: String) -> String {
        value
            .components(separatedBy: .newlines)
            .map(cleanInline)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func cleanInline(_ value: String) -> String {
        let bulletSymbols = ["•", "▪", "◆", "❖", "◈", "●", "○", "■", "□"]
        let withoutBullets = bulletSymbols.reduce(value) { partialResult, symbol in
            partialResult.replacingOccurrences(of: symbol, with: " ")
        }

        return withoutBullets
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
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

    private func lowercasedFirstPersonSentence(_ value: String) -> String {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.hasPrefix("I "), cleaned.count > 2 else {
            return lowercased(cleaned)
        }
        return "I \(lowercased(String(cleaned.dropFirst(2))))"
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
