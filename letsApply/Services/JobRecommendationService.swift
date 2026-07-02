//
//  JobRecommendationService.swift
//  letsApply
//

import Foundation

final class JobRecommendationService {

    func rank(jobs: [Job], for profile: UserProfile) -> [Job] {
        let desiredTitle = profile.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let profileTerms = weightedProfileTerms(profile)

        guard !profileTerms.isEmpty else {
            return jobs
        }

        return jobs.enumerated()
            .map { index, job in
                (job: job, score: score(job, desiredTitle: desiredTitle, profileTerms: profileTerms), index: index)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.index < $1.index
                }
                return $0.score > $1.score
            }
            .map(\.job)
    }

    private func weightedProfileTerms(_ profile: UserProfile) -> [String: Int] {
        var terms: [String: Int] = [:]

        addTerms(from: profile.jobTitle, weight: 8, to: &terms)
        profile.skills.forEach { addTerms(from: $0, weight: 5, to: &terms) }
        profile.qualifications.forEach { addTerms(from: $0, weight: 3, to: &terms) }
        addTerms(from: profile.professionalSummary, weight: 1, to: &terms)

        return terms
    }

    private func score(
        _ job: Job,
        desiredTitle: String,
        profileTerms: [String: Int]
    ) -> Int {
        let title = job.title.lowercased()
        let searchableText = [
            job.title,
            job.companyName,
            job.jobCategory,
            job.description,
            job.requirements.joined(separator: " "),
            job.qualifications.joined(separator: " "),
            job.responsibilities.joined(separator: " ")
        ].joined(separator: " ")

        let jobTerms = Set(tokens(from: searchableText))
        var result = profileTerms.reduce(0) { partialResult, entry in
            partialResult + (jobTerms.contains(entry.key) ? entry.value : 0)
        }

        let normalizedDesiredTitle = desiredTitle.lowercased()
        if !normalizedDesiredTitle.isEmpty && title.contains(normalizedDesiredTitle) {
            result += 30
        }

        if job.isFeatured {
            result += 1
        }

        return result
    }

    private func addTerms(
        from value: String,
        weight: Int,
        to terms: inout [String: Int]
    ) {
        tokens(from: value).forEach { token in
            terms[token] = max(weight, terms[token] ?? 0)
        }
    }

    private func tokens(from value: String) -> [String] {
        let ignoredTerms: Set<String> = [
            "and", "are", "for", "from", "into", "the", "this", "that",
            "with", "your", "you", "our", "will", "have", "has"
        ]

        return value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !ignoredTerms.contains($0) }
    }
}
