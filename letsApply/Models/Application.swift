//
//  Application.swift
//  letsApply
//

import Foundation

struct Application: Codable {
    var id: String
    var userId: String
    var jobId: String
    var jobTitle: String
    var companyName: String
    var appliedDate: String
    var status: String
    var cvUrl: String?
    var coverLetterText: String?
    var isAIGenerated: Bool?
    var tailoredCVText: String?
    var recruiterEmailSubject: String?
    var recruiterEmailBody: String?
    var matchScore: Int?
}

struct SavedJob: Codable {
    var id: String
    var userId: String
    var jobId: String
    var jobTitle: String
    var companyName: String
    var savedDate: String
}
