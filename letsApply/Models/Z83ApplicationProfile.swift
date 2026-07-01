//
//  Z83ApplicationProfile.swift
//  letsApply
//

import CoreGraphics
import Foundation

enum Z83YesNo: String, Codable, CaseIterable {
    case yes
    case no

    var title: String {
        rawValue.capitalized
    }
}

struct SignaturePoint: Codable, Equatable {
    let x: Double
    let y: Double

    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct SignatureStroke: Codable, Equatable {
    let points: [SignaturePoint]
}

struct Z83ApplicationProfile: Codable {
    var fullName: String
    var dateOfBirth: String
    var identityNumber: String
    var passportNumber: String
    var race: String
    var gender: String
    var hasDisability: Z83YesNo?
    var isSouthAfricanCitizen: Z83YesNo?
    var nationality: String
    var hasValidWorkPermit: Z83YesNo?
    var hasCriminalConviction: Z83YesNo?
    var criminalConvictionDetails: String
    var hasPendingCriminalCase: Z83YesNo?
    var pendingCriminalCaseDetails: String
    var dismissedForPublicServiceMisconduct: Z83YesNo?
    var dismissalDetails: String
    var hasPendingDisciplinaryCase: Z83YesNo?
    var disciplinaryCaseDetails: String
    var resignedPendingDisciplinaryProceedings: Z83YesNo?
    var resignationDetails: String
    var dischargedForIllHealth: Z83YesNo?
    var illHealthDetails: String
    var conductsBusinessWithState: Z83YesNo?
    var businessWithStateDetails: String
    var willRelinquishBusinessInterests: Z83YesNo?
    var privateSectorYears: String
    var publicSectorYears: String
    var registrationDate: String
    var registrationNumber: String
    var preferredLanguage: String
    var communicationMethod: String
    var availability: String
    var previousPublicServiceRestriction: Z83YesNo?
    var previousPublicServiceRestrictionDetails: String
    var signatureStrokes: [SignatureStroke]
    var declarationAccepted: Bool

    init(
        fullName: String = "",
        dateOfBirth: String = "",
        identityNumber: String = "",
        passportNumber: String = "",
        race: String = "",
        gender: String = "",
        hasDisability: Z83YesNo? = nil,
        isSouthAfricanCitizen: Z83YesNo? = nil,
        nationality: String = "",
        hasValidWorkPermit: Z83YesNo? = nil,
        hasCriminalConviction: Z83YesNo? = nil,
        criminalConvictionDetails: String = "",
        hasPendingCriminalCase: Z83YesNo? = nil,
        pendingCriminalCaseDetails: String = "",
        dismissedForPublicServiceMisconduct: Z83YesNo? = nil,
        dismissalDetails: String = "",
        hasPendingDisciplinaryCase: Z83YesNo? = nil,
        disciplinaryCaseDetails: String = "",
        resignedPendingDisciplinaryProceedings: Z83YesNo? = nil,
        resignationDetails: String = "",
        dischargedForIllHealth: Z83YesNo? = nil,
        illHealthDetails: String = "",
        conductsBusinessWithState: Z83YesNo? = nil,
        businessWithStateDetails: String = "",
        willRelinquishBusinessInterests: Z83YesNo? = nil,
        privateSectorYears: String = "",
        publicSectorYears: String = "",
        registrationDate: String = "",
        registrationNumber: String = "",
        preferredLanguage: String = "English",
        communicationMethod: String = "Email",
        availability: String = "",
        previousPublicServiceRestriction: Z83YesNo? = nil,
        previousPublicServiceRestrictionDetails: String = "",
        signatureStrokes: [SignatureStroke] = [],
        declarationAccepted: Bool = false
    ) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.identityNumber = identityNumber
        self.passportNumber = passportNumber
        self.race = race
        self.gender = gender
        self.hasDisability = hasDisability
        self.isSouthAfricanCitizen = isSouthAfricanCitizen
        self.nationality = nationality
        self.hasValidWorkPermit = hasValidWorkPermit
        self.hasCriminalConviction = hasCriminalConviction
        self.criminalConvictionDetails = criminalConvictionDetails
        self.hasPendingCriminalCase = hasPendingCriminalCase
        self.pendingCriminalCaseDetails = pendingCriminalCaseDetails
        self.dismissedForPublicServiceMisconduct = dismissedForPublicServiceMisconduct
        self.dismissalDetails = dismissalDetails
        self.hasPendingDisciplinaryCase = hasPendingDisciplinaryCase
        self.disciplinaryCaseDetails = disciplinaryCaseDetails
        self.resignedPendingDisciplinaryProceedings = resignedPendingDisciplinaryProceedings
        self.resignationDetails = resignationDetails
        self.dischargedForIllHealth = dischargedForIllHealth
        self.illHealthDetails = illHealthDetails
        self.conductsBusinessWithState = conductsBusinessWithState
        self.businessWithStateDetails = businessWithStateDetails
        self.willRelinquishBusinessInterests = willRelinquishBusinessInterests
        self.privateSectorYears = privateSectorYears
        self.publicSectorYears = publicSectorYears
        self.registrationDate = registrationDate
        self.registrationNumber = registrationNumber
        self.preferredLanguage = preferredLanguage
        self.communicationMethod = communicationMethod
        self.availability = availability
        self.previousPublicServiceRestriction = previousPublicServiceRestriction
        self.previousPublicServiceRestrictionDetails = previousPublicServiceRestrictionDetails
        self.signatureStrokes = signatureStrokes
        self.declarationAccepted = declarationAccepted
    }

    static func make(for profile: UserProfile, saved: Z83ApplicationProfile?) -> Z83ApplicationProfile {
        var value = saved ?? Z83ApplicationProfile()
        value.fullName = profile.name
        return value
    }

    var missingRequiredFields: [String] {
        var fields: [String] = []

        if fullName.trimmed.isEmpty { fields.append("Full name") }
        if dateOfBirth.trimmed.isEmpty { fields.append("Date of birth") }
        if identityNumber.trimmed.isEmpty && passportNumber.trimmed.isEmpty {
            fields.append("Identity or passport number")
        }
        if race.trimmed.isEmpty { fields.append("Race") }
        if gender.trimmed.isEmpty { fields.append("Gender") }
        if hasDisability == nil { fields.append("Disability declaration") }
        if isSouthAfricanCitizen == nil { fields.append("Citizenship declaration") }
        if isSouthAfricanCitizen == .no && nationality.trimmed.isEmpty {
            fields.append("Nationality")
        }
        if hasValidWorkPermit == nil { fields.append("Work permit declaration") }
        if hasCriminalConviction == nil { fields.append("Criminal conviction declaration") }
        if hasCriminalConviction == .yes && criminalConvictionDetails.trimmed.isEmpty {
            fields.append("Criminal conviction details")
        }
        if hasPendingCriminalCase == nil { fields.append("Pending criminal case declaration") }
        if hasPendingCriminalCase == .yes && pendingCriminalCaseDetails.trimmed.isEmpty {
            fields.append("Pending criminal case details")
        }
        if dismissedForPublicServiceMisconduct == nil {
            fields.append("Public Service dismissal declaration")
        }
        if dismissedForPublicServiceMisconduct == .yes && dismissalDetails.trimmed.isEmpty {
            fields.append("Public Service dismissal details")
        }
        if hasPendingDisciplinaryCase == nil {
            fields.append("Pending disciplinary case declaration")
        }
        if hasPendingDisciplinaryCase == .yes && disciplinaryCaseDetails.trimmed.isEmpty {
            fields.append("Pending disciplinary case details")
        }
        if resignedPendingDisciplinaryProceedings == nil {
            fields.append("Resignation declaration")
        }
        if resignedPendingDisciplinaryProceedings == .yes && resignationDetails.trimmed.isEmpty {
            fields.append("Resignation details")
        }
        if dischargedForIllHealth == nil {
            fields.append("Public Service ill-health declaration")
        }
        if dischargedForIllHealth == .yes && illHealthDetails.trimmed.isEmpty {
            fields.append("Public Service ill-health details")
        }
        if conductsBusinessWithState == nil {
            fields.append("Business interests declaration")
        }
        if conductsBusinessWithState == .yes && businessWithStateDetails.trimmed.isEmpty {
            fields.append("Business interests details")
        }
        if willRelinquishBusinessInterests == nil {
            fields.append("Relinquishment declaration")
        }
        if previousPublicServiceRestriction == nil {
            fields.append("Previous Public Service restriction declaration")
        }
        if previousPublicServiceRestriction == .yes
            && previousPublicServiceRestrictionDetails.trimmed.isEmpty {
            fields.append("Previous Public Service restriction details")
        }
        if preferredLanguage.trimmed.isEmpty { fields.append("Preferred language") }
        if availability.trimmed.isEmpty { fields.append("Availability or notice period") }
        if signatureStrokes.isEmpty { fields.append("Signature") }
        if !declarationAccepted { fields.append("Declaration acceptance") }

        return fields
    }

    var isComplete: Bool {
        missingRequiredFields.isEmpty
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
