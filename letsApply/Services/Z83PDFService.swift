//
//  Z83PDFService.swift
//  letsApply
//

import PDFKit
import UIKit

final class Z83PDFService {

    private var selectedButtonStates: [String: String] = [:]

    private struct WidgetSnapshot {
        let fieldName: String?
        let bounds: CGRect
        let fieldType: PDFAnnotationWidgetSubtype?
        let textValue: String?
        let isSelected: Bool
    }

    enum Z83PDFError: LocalizedError {
        case templateMissing
        case templateUnreadable
        case incomplete([String])
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .templateMissing:
                return "The official Z83 template is missing from the app."
            case .templateUnreadable:
                return "The official Z83 template could not be opened."
            case .incomplete(let fields):
                return "Complete these Z83 items first: \(fields.joined(separator: ", "))."
            case .writeFailed:
                return "The completed Z83 form could not be saved."
            }
        }
    }

    func generateZ83(
        profile: Z83ApplicationProfile,
        userProfile: UserProfile,
        job: Job
    ) throws -> URL {
        selectedButtonStates.removeAll()

        guard profile.isComplete else {
            throw Z83PDFError.incomplete(profile.missingRequiredFields)
        }

        guard let templateURL = Bundle.main.url(
            forResource: "Z83_Form_2020",
            withExtension: "pdf"
        ) else {
            throw Z83PDFError.templateMissing
        }

        guard let document = PDFDocument(url: templateURL) else {
            throw Z83PDFError.templateUnreadable
        }

        fillAdvertisedPost(in: document, profile: profile, job: job)
        fillPersonalInformation(in: document, profile: profile)
        fillContactInformation(in: document, profile: profile, userProfile: userProfile)
        fillEducation(in: document, userProfile: userProfile)
        fillExperience(in: document, userProfile: userProfile)
        fillReferences(in: document, userProfile: userProfile)
        fillSignature(in: document, profile: profile)

        let safeName = userProfile.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        let fileName = safeName.isEmpty ? "Completed_Z83.pdf" : "\(safeName)_Z83.pdf"
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        try renderFlattened(
            document: document,
            signatureStrokes: profile.signatureStrokes,
            to: outputURL
        )

        return outputURL
    }

    private func fillAdvertisedPost(
        in document: PDFDocument,
        profile: Z83ApplicationProfile,
        job: Job
    ) {
        setText(
            "Position for which you are applying as advertised",
            value: job.title,
            in: document
        )
        setText(
            "Department where the position was advertised",
            value: job.companyName,
            in: document
        )
        setText(
            "Reference number as stated in the advert",
            value: job.application.referenceNumber,
            in: document
        )
        setText(
            "If you are offered the position when can you start OR how much notice must you serve with your current employer",
            value: profile.availability,
            in: document
        )
    }

    private func fillPersonalInformation(
        in document: PDFDocument,
        profile: Z83ApplicationProfile
    ) {
        setText("Surname and Full names", value: profile.fullName, in: document)
        setText("Surname and Full names_2", value: profile.fullName, in: document)
        setText("DDMMYY", value: profile.dateOfBirth, in: document)
        setText("Identity Number", value: profile.identityNumber, in: document)
        setText("Passport2 number", value: profile.passportNumber, in: document)
        setText("Text5", value: profile.nationality, in: document)
        setText("Text6", value: profile.criminalConvictionDetails, in: document)
        setText("Text7", value: profile.pendingCriminalCaseDetails, in: document)
        setText("Text8", value: profile.dismissalDetails, in: document)
        setText("Text9", value: profile.disciplinaryCaseDetails, in: document)
        setText("Text10", value: profile.resignationDetails, in: document)
        setText("Text11", value: profile.illHealthDetails, in: document)
        setText("Text12", value: profile.privateSectorYears, in: document)
        setText("Text14", value: profile.publicSectorYears, in: document)
        setText("Text15", value: profile.registrationDate, in: document)
        setText("Text16", value: profile.registrationNumber, in: document)

        let raceStates = [
            "African": "Choice1",
            "White": "Choice2",
            "Coloured": "Choice3",
            "Indian": "Choice4",
            "Other": "Choice5"
        ]
        setButtonGroup("Group2", selectedState: raceStates[profile.race], in: document)
        setButtonGroup(
            "Group3",
            selectedState: profile.gender == "Female" ? "Choice6" : "Choice7",
            in: document
        )
        setYesNo("Group4", value: profile.hasDisability, in: document)
        setYesNo("Group5", value: profile.isSouthAfricanCitizen, in: document)
        setYesNo("Group6", value: profile.hasValidWorkPermit, in: document)
        setYesNo("Group7", value: profile.hasCriminalConviction, in: document)
        setYesNo("Group8", value: profile.hasPendingCriminalCase, in: document)
        setYesNo("Group9", value: profile.dismissedForPublicServiceMisconduct, in: document)
        setYesNo("Group10", value: profile.hasPendingDisciplinaryCase, in: document)
        setYesNo("Group11", value: profile.resignedPendingDisciplinaryProceedings, in: document)
        setYesNo("Group12", value: profile.dischargedForIllHealth, in: document)
        setYesNo("Group13", value: profile.conductsBusinessWithState, in: document)
        setYesNo("Group14", value: profile.willRelinquishBusinessInterests, in: document)
    }

    private func fillContactInformation(
        in document: PDFDocument,
        profile: Z83ApplicationProfile,
        userProfile: UserProfile
    ) {
        setText(
            "Preferred language for correspondence",
            value: profile.preferredLanguage,
            in: document
        )
        let contact = [userProfile.email, userProfile.phone]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        setText("Contact details in terms of the above", value: contact, in: document)

        let communicationStates = [
            "Post": "Choice1",
            "Email": "Choice2",
            "Fax": "Choice3",
            "Telephone": "Choice4"
        ]
        setButtonGroup(
            "Group16",
            selectedState: communicationStates[profile.communicationMethod],
            in: document
        )

        setButtonGroup(
            "Group17",
            selectedState: profile.previousPublicServiceRestriction == .yes
                ? "Choice1"
                : "Choice2",
            in: document
        )
        setText(
            "If yes Provide the name of the previous employing department and indicate the nature of the condition",
            value: profile.previousPublicServiceRestrictionDetails,
            in: document
        )
    }

    private func fillEducation(in document: PDFDocument, userProfile: UserProfile) {
        let entries = Array(userProfile.resolvedEducationEntries.prefix(4))
        for (index, entry) in entries.enumerated() {
            let row = index + 1
            setText(
                "Name of SchoolTechnical CollegeRow\(row)",
                value: entry.institution,
                in: document
            )
            let qualification = [entry.qualification, entry.fieldOfStudy]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " - ")
            setText(
                "Name of qualification obtainedRow\(row)",
                value: qualification,
                in: document
            )
            setText(
                "Year obtainedRow\(row)",
                value: entry.endYear,
                in: document
            )
        }
    }

    private func fillExperience(in document: PDFDocument, userProfile: UserProfile) {
        let entries = Array(userProfile.resolvedWorkExperiences.prefix(3))
        for (index, entry) in entries.enumerated() {
            let row = index + 1
            setText(
                "Employer including current employerRow\(row)",
                value: entry.company,
                in: document
            )
            setText("Post heldRow\(row)", value: entry.jobTitle, in: document)
            setText("YYRow\(row)", value: year(from: entry.startDate), in: document)
            setText("YYRow\(row)_2", value: year(from: entry.endDate), in: document)
        }
    }

    private func fillReferences(in document: PDFDocument, userProfile: UserProfile) {
        let entries = Array(userProfile.references.prefix(3))
        for (index, entry) in entries.enumerated() {
            let row = index + 1
            setText("NameRow\(row)", value: entry.name, in: document)
            let relationship = entry.relationship.isEmpty ? entry.jobTitle : entry.relationship
            setText("Relationship to youRow\(row)", value: relationship, in: document)
            setText("Tel No office hoursRow\(row)", value: entry.phone, in: document)
        }
    }

    private func fillSignature(
        in document: PDFDocument,
        profile: Z83ApplicationProfile
    ) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_ZA")
        formatter.dateFormat = "dd/MM/yyyy"
        let date = formatter.string(from: Date())
        let initials = profile.fullName
            .split(separator: " ")
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()

        setText("Date", value: date, in: document)
        setText("Initials", value: initials, in: document)
        setText("Text1", value: initials, in: document)

        setText("Signature", value: "", in: document)
    }

    private func setYesNo(
        _ fieldName: String,
        value: Z83YesNo?,
        in document: PDFDocument
    ) {
        let state = value == .yes ? "Choice6" : "Choice7"
        setButtonGroup(fieldName, selectedState: state, in: document)
    }

    private func setButtonGroup(
        _ fieldName: String,
        selectedState: String?,
        in document: PDFDocument
    ) {
        if let selectedState {
            selectedButtonStates[fieldName] = selectedState
        }
        annotations(named: fieldName, in: document).forEach { annotation in
            annotation.buttonWidgetState = annotation.buttonWidgetStateString == selectedState
                ? .onState
                : .offState
        }
    }

    private func setText(_ fieldName: String, value: String, in document: PDFDocument) {
        annotations(named: fieldName, in: document).forEach {
            $0.widgetStringValue = value
        }
    }

    private func annotations(named fieldName: String, in document: PDFDocument) -> [PDFAnnotation] {
        (0..<document.pageCount)
            .compactMap(document.page(at:))
            .flatMap(\.annotations)
            .filter { $0.fieldName == fieldName }
    }

    private func year(from value: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: "\\d{4}") else {
            return value
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = expression.matches(in: value, range: range).last,
              let matchRange = Range(match.range, in: value) else {
            return value
        }
        return String(value[matchRange])
    }

    private func renderFlattened(
        document: PDFDocument,
        signatureStrokes: [SignatureStroke],
        to outputURL: URL
    ) throws {
        guard let firstPage = document.page(at: 0) else {
            throw Z83PDFError.templateUnreadable
        }

        let pageBounds = firstPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        do {
            try renderer.writePDF(to: outputURL) { context in
                for pageIndex in 0..<document.pageCount {
                    guard let page = document.page(at: pageIndex) else { continue }
                    let widgets = page.annotations.map {
                        let selectedState = selectedButtonStates[$0.fieldName ?? ""]
                        return WidgetSnapshot(
                            fieldName: $0.fieldName,
                            bounds: $0.bounds,
                            fieldType: $0.widgetFieldType,
                            textValue: $0.widgetStringValue,
                            isSelected: $0.buttonWidgetState == .onState
                                || selectedState == $0.buttonWidgetStateString
                        )
                    }
                    page.annotations.forEach(page.removeAnnotation)

                    context.beginPage()
                    drawOriginalPage(page, in: context.cgContext, pageBounds: pageBounds)
                    drawWidgetValues(widgets, pageBounds: pageBounds)

                    if pageIndex == 1 {
                        drawSignature(
                            signatureStrokes,
                            widgets: widgets,
                            pageBounds: pageBounds
                        )
                    }
                }
            }
        } catch {
            throw Z83PDFError.writeFailed
        }
    }

    private func drawOriginalPage(
        _ page: PDFPage,
        in context: CGContext,
        pageBounds: CGRect
    ) {
        context.saveGState()
        context.translateBy(x: 0, y: pageBounds.height)
        context.scaleBy(x: 1, y: -1)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }

    private func drawWidgetValues(
        _ widgets: [WidgetSnapshot],
        pageBounds: CGRect
    ) {
        widgets.forEach { widget in
            let rect = uiRect(from: widget.bounds, pageBounds: pageBounds)

            if widget.fieldType == PDFAnnotationWidgetSubtype.text,
               let value = widget.textValue,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawText(value, in: rect)
            }

            if widget.fieldType == PDFAnnotationWidgetSubtype.button,
               widget.isSelected {
                drawCheckmark(in: rect)
            }
        }
    }

    private func drawText(_ value: String, in rect: CGRect) {
        let insetRect = rect.insetBy(dx: 2.5, dy: 1.5)
        let fontSize = min(8, max(5.5, insetRect.height * 0.55))
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.alignment = .left

        NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraph
            ]
        ).draw(
            with: insetRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private func drawCheckmark(in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(1.4)
        context?.setLineCap(.round)
        context?.move(to: CGPoint(x: rect.minX + 3, y: rect.midY))
        context?.addLine(to: CGPoint(x: rect.midX - 1, y: rect.maxY - 3))
        context?.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.minY + 3))
        context?.strokePath()
        context?.restoreGState()
    }

    private func drawSignature(
        _ strokes: [SignatureStroke],
        widgets: [WidgetSnapshot],
        pageBounds: CGRect
    ) {
        guard let signatureWidget = widgets.first(where: {
            $0.fieldName == "Signature"
        }), let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let rect = uiRect(from: signatureWidget.bounds, pageBounds: pageBounds)
            .insetBy(dx: 4, dy: 2)
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.25)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        strokes.forEach { stroke in
            guard let first = stroke.points.first?.cgPoint else { return }
            context.beginPath()
            context.move(to: signaturePoint(first, in: rect))
            stroke.points.dropFirst().forEach {
                context.addLine(to: signaturePoint($0.cgPoint, in: rect))
            }
            context.strokePath()
        }
        context.restoreGState()
    }

    private func signaturePoint(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + (point.x * rect.width),
            y: rect.minY + (point.y * rect.height)
        )
    }

    private func uiRect(from pdfRect: CGRect, pageBounds: CGRect) -> CGRect {
        let rect = pdfRect.standardized
        return CGRect(
            x: rect.minX,
            y: pageBounds.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
