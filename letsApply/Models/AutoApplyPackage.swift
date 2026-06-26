//
//  AutoApplyPackage.swift
//  letsApply
//

import Foundation

struct AutoApplyPackage {
    let matchScore: Int
    let matchSummary: String
    let missingSkills: [String]
    let recommendations: [String]
    let tailoredCVText: String
    let coverLetterText: String
    let emailSubject: String
    let emailBody: String
}
