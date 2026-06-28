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
    let sourceName: String
    let sourceUrl: String
    let sourceJobId: String
    let sourceType: String
    let dateImported: String
    let verified: Bool

    init(
        id: String?,
        title: String,
        companyName: String,
        companyImageName: String?,
        location: Location,
        jobType: String,
        remote: Bool,
        description: String,
        qualifications: [String],
        responsibilities: [String],
        requirements: [String],
        experience: Experience,
        compensation: Compensation,
        application: JobApplicationInfo,
        jobCategory: String,
        postingDate: String,
        visibility: Visibility,
        promoted: [String]?,
        sourceName: String = "Let’s Apply",
        sourceUrl: String = "",
        sourceJobId: String = "",
        sourceType: String = JobSourceType.manual.rawValue,
        dateImported: String = "",
        verified: Bool = false
    ) {
        self.id = id
        self.title = title
        self.companyName = companyName
        self.companyImageName = companyImageName
        self.location = location
        self.jobType = jobType
        self.remote = remote
        self.description = description
        self.qualifications = qualifications
        self.responsibilities = responsibilities
        self.requirements = requirements
        self.experience = experience
        self.compensation = compensation
        self.application = application
        self.jobCategory = jobCategory
        self.postingDate = postingDate
        self.visibility = visibility
        self.promoted = promoted
        self.sourceName = sourceName
        self.sourceUrl = sourceUrl
        self.sourceJobId = sourceJobId
        self.sourceType = sourceType
        self.dateImported = dateImported
        self.verified = verified
    }

    var isFeatured: Bool {
        return visibility.featured
    }

    var isPromoted: Bool {
        return visibility.promoted
    }

    var salaryText: String {
        compensation.salaryRange.displayText
    }

    var locationText: String {
        [location.city, location.region, location.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var applicationRoute: JobApplicationRoute {
        switch application.method.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "in-app", "inapp", "internal":
            return .inApp
        case "email":
            return .email
        case "portal", "external", "external-portal":
            return .externalPortal
        case "form", "required-form", "z83":
            return .requiredForm
        case "manual", "manual-instructions":
            return .manual
        default:
            break
        }

        let searchableText = [
            title,
            companyName,
            description,
            application.formName,
            application.requiredForms.joined(separator: " "),
            application.requiredDocuments.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()

        if !application.formName.isEmpty
            || !application.requiredForms.isEmpty
            || !application.requiredDocuments.isEmpty
            || application.requiresZ83
            || searchableText.contains("z83") {
            return .requiredForm
        }

        if !application.applicationUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .externalPortal
        }

        if !application.applicationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .email
        }

        if !application.applicationInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .manual
        }

        return .inApp
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
    let period: String?

    init(min: Int, max: Int, currency: String, period: String? = nil) {
        self.min = min
        self.max = max
        self.currency = currency
        self.period = period
    }

    var displayText: String {
        guard min > 0 || max > 0 else {
            return "Salary not disclosed"
        }

        let minimumText = min > 0 ? formattedAmount(min) : nil
        let maximumText = max > 0 ? formattedAmount(max) : nil
        let amountText: String

        switch (minimumText, maximumText) {
        case let (minimum?, _?) where min == max:
            amountText = minimum
        case let (minimum?, maximum?):
            amountText = "\(minimum) to \(maximum)"
        case let (minimum?, nil):
            amountText = "From \(minimum)"
        case let (nil, maximum?):
            amountText = "Up to \(maximum)"
        default:
            return "Salary not disclosed"
        }

        return "\(amountText) \(resolvedPeriod.displayText)"
    }

    private var resolvedPeriod: SalaryPayPeriod {
        if let period = period, let explicitPeriod = SalaryPayPeriod(rawValue: period) {
            return explicitPeriod
        }

        let normalizedPeriod = period?
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if normalizedPeriod.contains("hour") {
            return .hour
        }

        if normalizedPeriod.contains("day") {
            return .day
        }

        if normalizedPeriod.contains("week") {
            return .week
        }

        if normalizedPeriod.contains("month") {
            return .month
        }

        if normalizedPeriod.contains("year")
            || normalizedPeriod.contains("annual")
            || normalizedPeriod.contains("annum") {
            return .annum
        }

        return .annum
    }

    private func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let numberText = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(currencyPrefix)\(numberText)"
    }

    private var currencyPrefix: String {
        switch currency
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() {
        case "ZAR", "R":
            return "R"
        case "USD", "$":
            return "$"
        case "GBP", "£":
            return "£"
        case "EUR", "€":
            return "€"
        default:
            let code = currency
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            return code.isEmpty ? "" : "\(code) "
        }
    }
}

struct JobApplicationInfo: Codable {
    let deadline: String
    let applicationUrl: String
    let applicationEmail: String
    let contactPhone: String
    let method: String
    let formName: String
    let requiredForms: [String]
    let requiredDocuments: [String]
    let applicationInstructions: String
    let requiresCoverLetter: Bool
    let requiresCV: Bool
    let requiresZ83: Bool
    let requiresCertifiedDocuments: Bool

    init(
        deadline: String,
        applicationUrl: String,
        applicationEmail: String,
        contactPhone: String,
        method: String = "",
        formName: String = "",
        requiredForms: [String] = [],
        requiredDocuments: [String] = [],
        applicationInstructions: String = "",
        requiresCoverLetter: Bool = true,
        requiresCV: Bool = true,
        requiresZ83: Bool = false,
        requiresCertifiedDocuments: Bool = false
    ) {
        self.deadline = deadline
        self.applicationUrl = applicationUrl
        self.applicationEmail = applicationEmail
        self.contactPhone = contactPhone
        self.method = method
        self.formName = formName
        self.requiredForms = requiredForms
        self.requiredDocuments = requiredDocuments
        self.applicationInstructions = applicationInstructions
        self.requiresCoverLetter = requiresCoverLetter
        self.requiresCV = requiresCV
        self.requiresZ83 = requiresZ83
        self.requiresCertifiedDocuments = requiresCertifiedDocuments
    }
}

struct Visibility: Codable {
    let featured: Bool
    let promoted: Bool
}

enum SalaryPayPeriod: String, Codable {
    case hour
    case day
    case week
    case month
    case annum

    var displayText: String {
        switch self {
        case .hour:
            return "per hour"
        case .day:
            return "per day"
        case .week:
            return "per week"
        case .month:
            return "per month"
        case .annum:
            return "per annum"
        }
    }
}

enum JobApplicationRoute: String, Codable {
    case inApp
    case email
    case externalPortal
    case requiredForm
    case manual

    var title: String {
        switch self {
        case .inApp:
            return "Submit in Let’s Apply"
        case .email:
            return "Apply by email"
        case .externalPortal:
            return "Employer application portal"
        case .requiredForm:
            return "Application form required"
        case .manual:
            return "Manual application instructions"
        }
    }

    var systemImageName: String {
        switch self {
        case .inApp:
            return "checkmark.shield.fill"
        case .email:
            return "envelope.fill"
        case .externalPortal:
            return "safari.fill"
        case .requiredForm:
            return "doc.text.fill"
        case .manual:
            return "list.clipboard.fill"
        }
    }

    var actionTitle: String {
        switch self {
        case .inApp:
            return "Approve & Submit Application"
        case .email:
            return "Approve & Open Email"
        case .externalPortal:
            return "Save Package & Open Portal"
        case .requiredForm:
            return "Prepare Documents & Open Form"
        case .manual:
            return "Review Application Instructions"
        }
    }

    var trackerValue: String {
        rawValue
    }
}

enum JobSourceType: String, Codable {
    case manual
    case recruiter
    case government
    case companyWebsite
    case partner
    case publicFeed
}
