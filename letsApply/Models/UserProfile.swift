//
//  UserProfile.swift
//  letsApply
//

import Foundation

struct CVWorkExperience: Codable, Identifiable, Equatable {
    var id: String
    var jobTitle: String
    var company: String
    var location: String
    var startDate: String
    var endDate: String
    var responsibilities: [String]

    init(
        id: String = UUID().uuidString,
        jobTitle: String = "",
        company: String = "",
        location: String = "",
        startDate: String = "",
        endDate: String = "",
        responsibilities: [String] = []
    ) {
        self.id = id
        self.jobTitle = jobTitle
        self.company = company
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.responsibilities = responsibilities
    }

    var dateRange: String {
        [startDate, endDate]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " - ")
    }
}

struct CVEducationEntry: Codable, Identifiable, Equatable {
    var id: String
    var qualification: String
    var institution: String
    var fieldOfStudy: String
    var startYear: String
    var endYear: String
    var details: String

    init(
        id: String = UUID().uuidString,
        qualification: String = "",
        institution: String = "",
        fieldOfStudy: String = "",
        startYear: String = "",
        endYear: String = "",
        details: String = ""
    ) {
        self.id = id
        self.qualification = qualification
        self.institution = institution
        self.fieldOfStudy = fieldOfStudy
        self.startYear = startYear
        self.endYear = endYear
        self.details = details
    }

    var dateRange: String {
        [startYear, endYear]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " - ")
    }
}

struct CVQualificationEntry: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var issuer: String
    var year: String

    init(
        id: String = UUID().uuidString,
        title: String = "",
        issuer: String = "",
        year: String = ""
    ) {
        self.id = id
        self.title = title
        self.issuer = issuer
        self.year = year
    }
}

struct CVReference: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var jobTitle: String
    var company: String
    var relationship: String
    var email: String
    var phone: String

    init(
        id: String = UUID().uuidString,
        name: String = "",
        jobTitle: String = "",
        company: String = "",
        relationship: String = "",
        email: String = "",
        phone: String = ""
    ) {
        self.id = id
        self.name = name
        self.jobTitle = jobTitle
        self.company = company
        self.relationship = relationship
        self.email = email
        self.phone = phone
    }
}

struct UserProfile: Codable {
    var uid: String
    var name: String
    var email: String
    var phone: String
    var location: String
    var profilePictureUrl: String?
    var profileImageData: Data?
    var cvUrl: String?
    var cvFileName: String?
    var professionalSummary: String
    var jobTitle: String
    var skills: [String]
    var qualifications: [String]
    var experience: String
    var education: String
    var workExperiences: [CVWorkExperience]
    var educationEntries: [CVEducationEntry]
    var qualificationEntries: [CVQualificationEntry]
    var references: [CVReference]
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

        if qualifications.isEmpty && qualificationEntries.isEmpty {
            fields.append("Certificates acquired")
        }

        if experience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && workExperiences.isEmpty {
            fields.append("Experience")
        }

        if education.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && educationEntries.isEmpty {
            fields.append("Education history")
        }

        return fields
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case email
        case phone
        case location
        case profilePictureUrl
        case profileImageData
        case cvUrl
        case cvFileName
        case professionalSummary
        case jobTitle
        case skills
        case qualifications
        case experience
        case education
        case workExperiences
        case educationEntries
        case qualificationEntries
        case references
        case savedJobs
        case isPremium
    }

    init(
        uid: String = "",
        name: String = "",
        email: String = "",
        phone: String = "",
        location: String = "",
        profilePictureUrl: String? = nil,
        profileImageData: Data? = nil,
        cvUrl: String? = nil,
        cvFileName: String? = nil,
        professionalSummary: String = "",
        jobTitle: String = "",
        skills: [String] = [],
        qualifications: [String] = [],
        experience: String = "",
        education: String = "",
        workExperiences: [CVWorkExperience] = [],
        educationEntries: [CVEducationEntry] = [],
        qualificationEntries: [CVQualificationEntry] = [],
        references: [CVReference] = [],
        savedJobs: [String] = [],
        isPremium: Bool = false
    ) {
        self.uid = uid
        self.name = name
        self.email = email
        self.phone = phone
        self.location = location
        self.profilePictureUrl = profilePictureUrl
        self.profileImageData = profileImageData
        self.cvUrl = cvUrl
        self.cvFileName = cvFileName
        self.professionalSummary = professionalSummary
        self.jobTitle = jobTitle
        self.skills = skills
        self.qualifications = qualifications
        self.experience = experience
        self.education = education
        self.workExperiences = workExperiences
        self.educationEntries = educationEntries
        self.qualificationEntries = qualificationEntries
        self.references = references
        self.savedJobs = savedJobs
        self.isPremium = isPremium
    }

    var resolvedWorkExperiences: [CVWorkExperience] {
        if !workExperiences.isEmpty {
            return workExperiences
        }

        let legacyExperience = experience.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !legacyExperience.isEmpty else { return [] }

        return [
            CVWorkExperience(
                jobTitle: jobTitle.isEmpty ? "Professional Experience" : jobTitle,
                responsibilities: legacyItems(from: legacyExperience)
            )
        ]
    }

    var resolvedEducationEntries: [CVEducationEntry] {
        if !educationEntries.isEmpty {
            return educationEntries
        }

        let legacyEducation = education.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !legacyEducation.isEmpty else { return [] }

        return [
            CVEducationEntry(
                qualification: "Education",
                details: legacyEducation
            )
        ]
    }

    var resolvedQualificationEntries: [CVQualificationEntry] {
        if !qualificationEntries.isEmpty {
            return qualificationEntries
        }

        return qualifications.map { CVQualificationEntry(title: $0) }
    }

    private func legacyItems(from value: String) -> [String] {
        let lines = value
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.isEmpty ? [value] : lines
    }
}
