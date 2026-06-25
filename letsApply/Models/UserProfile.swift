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
    var jobTitle: String
    var skills: [String]
    var qualifications: [String]
    var experience: String
    var education: String
    var savedJobs: [String]
    var isPremium: Bool

    var isComplete: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !skills.isEmpty &&
        !qualifications.isEmpty &&
        !experience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !education.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case email
        case location
        case profilePictureUrl
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
        self.jobTitle = jobTitle
        self.skills = skills
        self.qualifications = qualifications
        self.experience = experience
        self.education = education
        self.savedJobs = savedJobs
        self.isPremium = isPremium
    }
}
