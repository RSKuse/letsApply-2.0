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

    var applicationMethod: JobApplicationMethod {
        let method = application.method
            .lowercased()
            .filter { $0.isLetter }
        switch method {
        case "inapp", "internal", "internalapply":
            return .internalApply
        case "email":
            return requiresGovernmentFlow ? .governmentEmail : .email
        case "portal", "external", "externalportal", "externalwebsite":
            return requiresGovernmentFlow ? .governmentWebsite : .externalWebsite
        case "governmentemail":
            return .governmentEmail
        case "governmentwebsite":
            return .governmentWebsite
        case "governmentmanual":
            return .governmentManual
        case "pdfcircular":
            return .pdfCircular
        case "form", "requiredform", "z83":
            if requiresGovernmentFlow {
                if !application.applicationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return .governmentEmail
                }
                if !application.applicationUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return .governmentWebsite
                }
                return .governmentManual
            }
            return .manualInstruction
        case "manual", "manualinstructions", "manualinstruction":
            return .manualInstruction
        default:
            break
        }

        if requiresGovernmentFlow {
            if !application.applicationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .governmentEmail
            }

            if !application.applicationUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .governmentWebsite
            }

            return sourceType.lowercased() == JobSourceType.publicFeed.rawValue.lowercased()
                ? .pdfCircular
                : .governmentManual
        }

        if !application.applicationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .email
        }

        if !application.applicationUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .externalWebsite
        }

        if !application.applicationInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .manualInstruction
        }

        return .internalApply
    }

    var applicationRoute: JobApplicationRoute {
        switch applicationMethod {
        case .internalApply:
            return .inApp
        case .email, .governmentEmail:
            return .email
        case .externalWebsite, .governmentWebsite:
            return .externalPortal
        case .governmentManual, .pdfCircular:
            return .requiredForm
        case .manualInstruction:
            return .manual
        }
    }

    var requiresGovernmentFlow: Bool {
        let searchableText = [
            title,
            companyName,
            description,
            sourceName,
            sourceType,
            application.formName,
            application.applicationInstructions,
            application.requiredForms.joined(separator: " "),
            application.requiredDocuments.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()

        return application.requiresZ83
            || sourceType.lowercased() == JobSourceType.government.rawValue.lowercased()
            || searchableText.contains("z83")
            || searchableText.contains("government")
            || searchableText.contains("dpsa")
            || searchableText.contains("department of")
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
    let referenceNumber: String
    let postalAddress: String
    let handDeliveryAddress: String
    let requiresDriversLicense: Bool

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
        requiresCertifiedDocuments: Bool = false,
        referenceNumber: String = "",
        postalAddress: String = "",
        handDeliveryAddress: String = "",
        requiresDriversLicense: Bool = false
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
        self.referenceNumber = referenceNumber
        self.postalAddress = postalAddress
        self.handDeliveryAddress = handDeliveryAddress
        self.requiresDriversLicense = requiresDriversLicense
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
            return "Apply directly in Let’s Apply"
        case .email:
            return "Send your application by email"
        case .externalPortal:
            return "Continue on the employer’s website"
        case .requiredForm:
            return "Complete the required forms"
        case .manual:
            return "Follow the employer’s instructions"
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
        return "Submit Application"
    }

    var progressTitle: String {
        switch self {
        case .inApp:
            return "Submitting..."
        case .email:
            return "Preparing Email..."
        case .externalPortal, .requiredForm:
            return "Preparing Documents..."
        case .manual:
            return "Saving Draft..."
        }
    }

    var trackerValue: String {
        rawValue
    }
}

enum JobApplicationMethod: String, Codable {
    case internalApply
    case email
    case externalWebsite
    case governmentEmail
    case governmentWebsite
    case governmentManual
    case pdfCircular
    case manualInstruction

    var reviewTitle: String {
        switch self {
        case .internalApply:
            return "Submit directly in Let’s Apply"
        case .email:
            return "Send with your email app"
        case .externalWebsite:
            return "Continue on the employer’s website"
        case .governmentEmail:
            return "Email a government application"
        case .governmentWebsite:
            return "Continue on the government website"
        case .governmentManual:
            return "Follow the government application instructions"
        case .pdfCircular:
            return "Apply using the vacancy circular instructions"
        case .manualInstruction:
            return "Follow the employer’s application instructions"
        }
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
