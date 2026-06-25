//
//  Job.swift
//  letsApply
//

import Foundation
import FirebaseFirestore

struct Job: Codable {
    let id: String?
    let title: String
    let companyName: String
    let companyImageName: String?
    let location: Location
    let jobType: String
    let remote: Bool
    let description: String
    let qualifications: [String]
    let responsibilities: [String]
    let requirements: [String]
    let experience: Experience
    let compensation: Compensation
    let application: JobApplicationInfo
    let jobCategory: String
    let postingDate: String
    let visibility: Visibility
    let promoted: [String]?

    var isFeatured: Bool {
        return visibility.featured
    }

    var isPromoted: Bool {
        return visibility.promoted
    }

    var salaryText: String {
        "\(compensation.salaryRange.currency) \(compensation.salaryRange.min) to \(compensation.salaryRange.max)"
    }

    var locationText: String {
        [location.city, location.region, location.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

struct Location: Codable {
    let city: String
    let region: String
    let country: String
}

struct Experience: Codable {
    let minYears: Int
    let preferredYears: Int
    let details: String
}

struct Compensation: Codable {
    let salaryRange: SalaryRange
    let benefits: [String]
}

struct SalaryRange: Codable {
    let min: Int
    let max: Int
    let currency: String
}

struct JobApplicationInfo: Codable {
    let deadline: String
    let applicationUrl: String
    let applicationEmail: String
    let contactPhone: String
}

struct Visibility: Codable {
    let featured: Bool
    let promoted: Bool
}
