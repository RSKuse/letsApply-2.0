//
//  JobFilters.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/25.
//

import Foundation

struct JobFilters {

    var keyword: String = ""
    var province: String = ""
    var city: String = ""
    var jobType: String = ""
    var category: String = ""
    var company: String = ""
    var remoteOnly: Bool = false
    var featuredOnly: Bool = false
    var minimumSalary: Int?

    func matches(_ job: Job) -> Bool {
        if remoteOnly && !job.remote {
            return false
        }

        if featuredOnly && !job.isFeatured {
            return false
        }

        if !province.isEmpty && !job.location.region.localizedCaseInsensitiveContains(province) {
            return false
        }

        if !city.isEmpty && !job.location.city.localizedCaseInsensitiveContains(city) {
            return false
        }

        if !jobType.isEmpty && !job.jobType.localizedCaseInsensitiveContains(jobType) {
            return false
        }

        if !category.isEmpty && !job.jobCategory.localizedCaseInsensitiveContains(category) {
            return false
        }

        if !company.isEmpty && !job.companyName.localizedCaseInsensitiveContains(company) {
            return false
        }

        if let minimumSalary = minimumSalary, job.compensation.salaryRange.max < minimumSalary {
            return false
        }

        if !keyword.isEmpty {
            let searchableText = [
                job.title,
                job.companyName,
                job.locationText,
                job.jobType,
                job.jobCategory,
                job.requirements.joined(separator: " "),
                job.qualifications.joined(separator: " ")
            ].joined(separator: " ")

            return searchableText.localizedCaseInsensitiveContains(keyword)
        }

        return true
    }
}
