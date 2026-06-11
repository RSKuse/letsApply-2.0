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

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case email
        case location
        case profilePictureUrl = "profile_picture_url"
        case jobTitle = "job_title"
        case skills
        case qualifications
        case experience
        case education
        case savedJobs = "saved_jobs"
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
        savedJobs: [String] = []
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
    }
}
