//
//  UserProfile.swift
//  letsApply
//

import Foundation

struct UserProfile: Codable {
    var uid: String
    var name: String
    var email: String
    var location: String
    var profilePictureUrl: String?
    var cvUrl: String?
    var cvFileName: String?
    var professionalSummary: String
    var jobTitle: String
    var skills: [String]
    var qualifications: [String]
    var experience: String
    var education: String
    var savedJobs: [String]
    var isPremium: Bool

    var isComplete: Bool {
        return missingRequiredFields.isEmpty
    }

    var completionPercentage: Int {
        let totalRequiredFields = 8
        let completedFields = totalRequiredFields - missingRequiredFields.count
        return Int((Double(completedFields) / Double(totalRequiredFields)) * 100)
    }

    var missingRequiredFields: [String] {
        var fields: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Full name")
        }

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Email")
        }

        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Location")
        }

        if jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Desired job title")
        }

        if skills.isEmpty {
            fields.append("Skills")
        }

        if qualifications.isEmpty {
            fields.append("Qualifications")
        }

        if experience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Experience")
        }

        if education.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Education")
        }

        return fields
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case email
        case location
        case profilePictureUrl
        case cvUrl
        case cvFileName
        case professionalSummary
        case jobTitle
        case skills
        case qualifications
        case experience
        case education
        case savedJobs
        case isPremium
    }

    init(
        uid: String = "",
        name: String = "",
        email: String = "",
        location: String = "",
        profilePictureUrl: String? = nil,
        cvUrl: String? = nil,
        cvFileName: String? = nil,
        professionalSummary: String = "",
        jobTitle: String = "",
        skills: [String] = [],
        qualifications: [String] = [],
        experience: String = "",
        education: String = "",
        savedJobs: [String] = [],
        isPremium: Bool = false
    ) {
        self.uid = uid
        self.name = name
        self.email = email
        self.location = location
        self.profilePictureUrl = profilePictureUrl
        self.cvUrl = cvUrl
        self.cvFileName = cvFileName
        self.professionalSummary = professionalSummary
        self.jobTitle = jobTitle
        self.skills = skills
        self.qualifications = qualifications
        self.experience = experience
        self.education = education
        self.savedJobs = savedJobs
        self.isPremium = isPremium
    }
}
