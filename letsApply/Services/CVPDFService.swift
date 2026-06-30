//
//  CVPDFService.swift
//  letsApply
//

import UIKit

final class CVPDFService {

    enum CVPDFError: LocalizedError {
        case missingName

        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Add your name to your profile before generating a CV."
            }
        }
    }

    func generateCV(for profile: UserProfile) throws -> URL {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw CVPDFError.missingName
        }

        let fileName = safeFileName(from: "\(name) CV")
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("pdf")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(name) CV",
            kCGPDFContextAuthor as String: name,
            kCGPDFContextCreator as String: "Let's Apply"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        try renderer.writePDF(to: fileURL) { context in
            CVPDFWriter(context: context, pageBounds: pageBounds, profile: profile).render()
        }

        return fileURL
    }

    func generateCoverLetter(
        for profile: UserProfile,
        job: Job,
        text: String
    ) throws -> URL {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw CVPDFError.missingName
        }

        let fileName = safeFileName(from: "\(name) \(job.title) Cover Letter")
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("pdf")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(job.title) Cover Letter",
            kCGPDFContextAuthor as String: name,
            kCGPDFContextCreator as String: "Let's Apply"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        try renderer.writePDF(to: fileURL) { context in
            CoverLetterPDFWriter(
                context: context,
                pageBounds: pageBounds,
                profile: profile,
                job: job,
                text: text
            ).render()
        }

        return fileURL
    }

    private func safeFileName(from value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let cleaned = value.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")

        return cleaned.isEmpty ? "Lets_Apply_CV" : cleaned
    }
}

private final class CoverLetterPDFWriter {

    private let context: UIGraphicsPDFRendererContext
    private let pageBounds: CGRect
    private let profile: UserProfile
    private let job: Job
    private let text: String
    private let margin: CGFloat = 54

    private let inkColor = UIColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1)
    private let brandColor = UIColor(red: 0.05, green: 0.48, blue: 0.32, alpha: 1)
    private let secondaryColor = UIColor(red: 0.34, green: 0.39, blue: 0.40, alpha: 1)

    init(
        context: UIGraphicsPDFRendererContext,
        pageBounds: CGRect,
        profile: UserProfile,
        job: Job,
        text: String
    ) {
        self.context = context
        self.pageBounds = pageBounds
        self.profile = profile
        self.job = job
        self.text = text
    }

    func render() {
        context.beginPage()

        brandColor.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: pageBounds.height))

        draw(
            profile.name.uppercased(),
            frame: CGRect(x: margin, y: 32, width: pageBounds.width - (margin * 2), height: 32),
            font: UIFont.systemFont(ofSize: 23, weight: .bold),
            color: inkColor,
            lineHeight: 28
        )

        let contactLine = [profile.email, profile.phone, profile.location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "  |  ")

        draw(
            contactLine,
            frame: CGRect(x: margin, y: 66, width: pageBounds.width - (margin * 2), height: 22),
            font: UIFont.systemFont(ofSize: 10, weight: .medium),
            color: secondaryColor,
            lineHeight: 14
        )

        brandColor.setFill()
        context.cgContext.fill(
            CGRect(x: margin, y: 98, width: pageBounds.width - (margin * 2), height: 2)
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        draw(
            dateFormatter.string(from: Date()),
            frame: CGRect(x: margin, y: 116, width: 220, height: 20),
            font: UIFont.systemFont(ofSize: 10.5, weight: .medium),
            color: secondaryColor,
            lineHeight: 14
        )

        draw(
            job.companyName,
            frame: CGRect(x: margin, y: 142, width: pageBounds.width - (margin * 2), height: 22),
            font: UIFont.systemFont(ofSize: 11.5, weight: .semibold),
            color: inkColor,
            lineHeight: 16
        )

        draw(
            "RE: APPLICATION FOR \(job.title.uppercased())",
            frame: CGRect(x: margin, y: 172, width: pageBounds.width - (margin * 2), height: 34),
            font: UIFont.systemFont(ofSize: 12, weight: .bold),
            color: brandColor,
            lineHeight: 17
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 9
        paragraphStyle.lineBreakMode = .byWordWrapping

        let body = NSAttributedString(
            string: text.trimmingCharacters(in: .whitespacesAndNewlines),
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: inkColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        body.draw(
            with: CGRect(
                x: margin,
                y: 214,
                width: pageBounds.width - (margin * 2),
                height: 526
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        draw(
            "Prepared locally with Let’s Apply",
            frame: CGRect(x: margin, y: 758, width: 260, height: 14),
            font: UIFont.systemFont(ofSize: 8, weight: .medium),
            color: secondaryColor,
            lineHeight: 10
        )
    }

    private func draw(
        _ value: String,
        frame: CGRect,
        font: UIFont,
        color: UIColor,
        lineHeight: CGFloat
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        NSAttributedString(
            string: value,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
        )
        .draw(
            with: frame,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }
}

private final class CVPDFWriter {

    private let context: UIGraphicsPDFRendererContext
    private let pageBounds: CGRect
    private let profile: UserProfile
    private let margin: CGFloat = 44
    private let bottomLimit: CGFloat = 756
    private var currentY: CGFloat = 0
    private var pageNumber = 0

    private let inkColor = UIColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1)
    private let brandColor = UIColor(red: 0.05, green: 0.48, blue: 0.32, alpha: 1)
    private let accentColor = UIColor(red: 0.19, green: 0.69, blue: 0.76, alpha: 1)
    private let sectionColor = UIColor(red: 0.91, green: 0.95, blue: 0.93, alpha: 1)
    private let bodyColor = UIColor(red: 0.12, green: 0.15, blue: 0.16, alpha: 1)
    private let secondaryColor = UIColor(red: 0.34, green: 0.39, blue: 0.40, alpha: 1)

    init(
        context: UIGraphicsPDFRendererContext,
        pageBounds: CGRect,
        profile: UserProfile
    ) {
        self.context = context
        self.pageBounds = pageBounds
        self.profile = profile
    }

    func render() {
        startPage(isFirstPage: true)

        drawSection(
            title: "PROFESSIONAL SUMMARY",
            text: profile.professionalSummary,
            fallback: "Professional profile available on request."
        )
        drawInlineListSection(title: "CORE SKILLS", items: profile.skills)
        drawWorkExperienceSection()
        drawEducationSection()
        drawQualificationsSection()
        drawReferencesSection()
    }

    private func startPage(isFirstPage: Bool) {
        context.beginPage()
        pageNumber += 1

        if isFirstPage {
            drawFirstPageHeader()
            currentY = 132
        } else {
            drawContinuationHeader()
            currentY = 78
        }

        drawFooter()
    }

    private func drawFirstPageHeader() {
        inkColor.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: pageBounds.width, height: 116))

        brandColor.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 116))

        draw(
            profile.name.uppercased(),
            in: CGRect(x: margin, y: 12, width: pageBounds.width - (margin * 2), height: 38),
            font: UIFont.systemFont(ofSize: 26, weight: .bold),
            color: .white,
            lineHeight: 30
        )

        let jobTitle = profile.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        draw(
            jobTitle.isEmpty ? "PROFESSIONAL CANDIDATE" : jobTitle.uppercased(),
            in: CGRect(x: margin, y: 47, width: pageBounds.width - (margin * 2), height: 24),
            font: UIFont.systemFont(ofSize: 13, weight: .bold),
            color: accentColor,
            lineHeight: 18
        )

        let contactLine = [profile.email, profile.phone, profile.location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "  |  ")

        draw(
            contactLine,
            in: CGRect(x: margin, y: 80, width: pageBounds.width - (margin * 2), height: 24),
            font: UIFont.systemFont(ofSize: 11, weight: .medium),
            color: UIColor.white.withAlphaComponent(0.78),
            lineHeight: 16
        )
    }

    private func drawContinuationHeader() {
        draw(
            profile.name,
            in: CGRect(x: margin, y: 28, width: 350, height: 24),
            font: UIFont.systemFont(ofSize: 15, weight: .bold),
            color: inkColor,
            lineHeight: 20
        )

        draw(
            "LET'S APPLY CV",
            in: CGRect(x: pageBounds.width - margin - 120, y: 30, width: 120, height: 20),
            font: UIFont.systemFont(ofSize: 10, weight: .bold),
            color: brandColor,
            lineHeight: 14,
            alignment: .right
        )

        brandColor.setFill()
        context.cgContext.fill(
            CGRect(x: margin, y: 60, width: pageBounds.width - (margin * 2), height: 2)
        )
    }

    private func drawFooter() {
        draw(
            "Generated locally with Let's Apply",
            in: CGRect(x: margin, y: 762, width: 250, height: 16),
            font: UIFont.systemFont(ofSize: 8, weight: .medium),
            color: secondaryColor,
            lineHeight: 10
        )

        draw(
            "Page \(pageNumber)",
            in: CGRect(x: pageBounds.width - margin - 80, y: 762, width: 80, height: 16),
            font: UIFont.systemFont(ofSize: 8, weight: .medium),
            color: secondaryColor,
            lineHeight: 10,
            alignment: .right
        )
    }

    private func drawListSection(title: String, items: [String]) {
        let text = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "- \($0)" }
            .joined(separator: "\n")

        drawSection(title: title, text: text)
    }

    private func drawWorkExperienceSection() {
        let entries = profile.resolvedWorkExperiences
        guard !entries.isEmpty else { return }

        ensureSpace(82)
        drawSectionTitle("WORK EXPERIENCE")

        for (index, entry) in entries.enumerated() {
            if index > 0 {
                currentY += 5
                prepareForEntry(requiredHeight: 70, continuationTitle: "WORK EXPERIENCE")
            }

            let title = entry.jobTitle.isEmpty ? "Professional Experience" : entry.jobTitle
            drawEntryHeader(title: title, metadata: entry.dateRange)

            let organisation = [entry.company, entry.location]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "  |  ")
            drawEntrySecondaryLine(organisation)

            for responsibility in entry.responsibilities {
                let cleaned = sanitize(responsibility)
                if !cleaned.isEmpty {
                    drawParagraph("- \(cleaned)")
                }
            }
        }

        currentY += 2
    }

    private func drawEducationSection() {
        let entries = profile.resolvedEducationEntries
        guard !entries.isEmpty else { return }

        ensureSpace(82)
        drawSectionTitle("EDUCATION")

        for (index, entry) in entries.enumerated() {
            if index > 0 {
                currentY += 5
                prepareForEntry(requiredHeight: 62, continuationTitle: "EDUCATION")
            }

            let title = entry.qualification.isEmpty ? "Education" : entry.qualification
            drawEntryHeader(title: title, metadata: entry.dateRange)

            let institution = [entry.institution, entry.fieldOfStudy]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "  |  ")
            drawEntrySecondaryLine(institution)

            let details = sanitize(entry.details)
            if !details.isEmpty {
                drawParagraph(details)
            }
        }

        currentY += 2
    }

    private func drawQualificationsSection() {
        let entries = profile.resolvedQualificationEntries
        guard !entries.isEmpty else { return }

        ensureSpace(76)
        drawSectionTitle("CERTIFICATES ACQUIRED")

        for (index, entry) in entries.enumerated() {
            if index > 0 {
                currentY += 5
                prepareForEntry(requiredHeight: 38, continuationTitle: "CERTIFICATES ACQUIRED")
            }

            let title = entry.title.isEmpty ? "Professional Qualification" : entry.title
            drawEntryHeader(title: title, metadata: entry.year)
            drawEntrySecondaryLine(entry.issuer)
        }

        currentY += 2
    }

    private func drawReferencesSection() {
        guard !profile.references.isEmpty else {
            drawSection(title: "REFERENCES", text: "Available upon request.")
            return
        }

        let referenceBlockHeight = 34 + (CGFloat(profile.references.count) * 62)
        ensureSpace(referenceBlockHeight)
        drawSectionTitle("REFERENCES")

        for (index, reference) in profile.references.enumerated() {
            if index > 0 {
                currentY += 5
                prepareForEntry(requiredHeight: 62, continuationTitle: "REFERENCES")
            }

            drawEntryHeader(title: reference.name, metadata: reference.relationship)

            let role = [reference.jobTitle, reference.company]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "  |  ")
            drawEntrySecondaryLine(role)

            let contact = [reference.email, reference.phone]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "  |  ")
            if !contact.isEmpty {
                drawParagraph(contact)
            }
        }

        currentY += 2
    }

    private func prepareForEntry(requiredHeight: CGFloat, continuationTitle: String) {
        guard currentY + requiredHeight > bottomLimit else { return }
        startPage(isFirstPage: false)
        drawSectionTitle("\(continuationTitle) CONTINUED")
    }

    private func drawEntryHeader(title: String, metadata: String) {
        let cleanTitle = sanitize(title)
        let cleanMetadata = sanitize(metadata)
        let metadataWidth: CGFloat = cleanMetadata.isEmpty ? 0 : 150
        let titleWidth = pageBounds.width - (margin * 2) - metadataWidth - 12
        let font = UIFont.systemFont(ofSize: 12, weight: .bold)
        let titleHeight = textHeight(
            for: cleanTitle,
            font: font,
            width: titleWidth,
            lineHeight: 16
        )
        let rowHeight = max(18, ceil(titleHeight))

        draw(
            cleanTitle,
            in: CGRect(x: margin, y: currentY, width: titleWidth, height: rowHeight + 2),
            font: font,
            color: inkColor,
            lineHeight: 16
        )

        if !cleanMetadata.isEmpty {
            draw(
                cleanMetadata,
                in: CGRect(
                    x: pageBounds.width - margin - metadataWidth,
                    y: currentY,
                    width: metadataWidth,
                    height: rowHeight + 2
                ),
                font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                color: secondaryColor,
                lineHeight: 14,
                alignment: .right
            )
        }

        currentY += rowHeight + 3
    }

    private func drawEntrySecondaryLine(_ text: String) {
        let cleanText = sanitize(text)
        guard !cleanText.isEmpty else { return }
        let font = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
        let height = textHeight(
            for: cleanText,
            font: font,
            width: pageBounds.width - (margin * 2),
            lineHeight: 15
        )

        draw(
            cleanText,
            in: CGRect(
                x: margin,
                y: currentY,
                width: pageBounds.width - (margin * 2),
                height: height + 2
            ),
            font: font,
            color: brandColor,
            lineHeight: 15
        )
        currentY += ceil(height) + 4
    }

    private func drawInlineListSection(title: String, items: [String]) {
        let text = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        drawSection(title: title, text: text)
    }

    private func drawSection(title: String, text: String, fallback: String? = nil) {
        let cleanedText = sanitize(text)
        let content = cleanedText.isEmpty ? (fallback ?? "") : cleanedText
        guard !content.isEmpty else { return }

        ensureSpace(54)
        drawSectionTitle(title)
        drawPaginatedText(content)
        currentY += 2
    }

    private func drawSectionTitle(_ title: String) {
        sectionColor.setFill()
        context.cgContext.fill(
            CGRect(x: margin, y: currentY, width: pageBounds.width - (margin * 2), height: 26)
        )

        brandColor.setFill()
        context.cgContext.fill(CGRect(x: margin, y: currentY, width: 5, height: 26))

        draw(
            title,
            in: CGRect(
                x: margin + 16,
                y: currentY + 5,
                width: pageBounds.width - (margin * 2) - 24,
                height: 18
            ),
            font: UIFont.systemFont(ofSize: 12, weight: .bold),
            color: inkColor,
            lineHeight: 15
        )

        currentY += 30
    }

    private func drawPaginatedText(_ text: String) {
        let paragraphs = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for paragraph in paragraphs {
            drawParagraph(paragraph)
        }
    }

    private func drawParagraph(_ paragraph: String) {
        var remainingWords = paragraph.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        while !remainingWords.isEmpty {
            if bottomLimit - currentY < 22 {
                startPage(isFirstPage: false)
            }

            let availableHeight = bottomLimit - currentY
            let fittingWordCount = maximumFittingWordCount(
                words: remainingWords,
                availableHeight: availableHeight
            )
            let count = max(1, fittingWordCount)
            let chunk = remainingWords.prefix(count).joined(separator: " ")
            let height = textHeight(for: chunk)

            draw(
                chunk,
                in: CGRect(
                    x: margin,
                    y: currentY,
                    width: pageBounds.width - (margin * 2),
                    height: height + 2
                ),
                font: bodyFont,
                color: bodyColor,
                lineHeight: 16
            )

            currentY += ceil(height) + 4
            remainingWords.removeFirst(count)
        }
    }

    private func maximumFittingWordCount(words: [String], availableHeight: CGFloat) -> Int {
        var lowerBound = 1
        var upperBound = words.count
        var bestFit = 0

        while lowerBound <= upperBound {
            let middle = (lowerBound + upperBound) / 2
            let candidate = words.prefix(middle).joined(separator: " ")
            let candidateHeight = textHeight(for: candidate)

            if candidateHeight <= availableHeight {
                bestFit = middle
                lowerBound = middle + 1
            } else {
                upperBound = middle - 1
            }
        }

        return bestFit
    }

    private var bodyFont: UIFont {
        UIFont.systemFont(ofSize: 11, weight: .regular)
    }

    private func textHeight(for text: String) -> CGFloat {
        return textHeight(
            for: text,
            font: bodyFont,
            width: pageBounds.width - (margin * 2),
            lineHeight: 16
        )
    }

    private func textHeight(
        for text: String,
        font: UIFont,
        width: CGFloat,
        lineHeight: CGFloat
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ],
            context: nil
        ).height
    }

    private func ensureSpace(_ requiredHeight: CGFloat) {
        if currentY + requiredHeight > bottomLimit {
            startPage(isFirstPage: false)
        }
    }

    private func sanitize(_ text: String) -> String {
        let cleanedText = text
            .replacingOccurrences(of: "❖", with: "-")
            .replacingOccurrences(of: "•", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let pattern = "\\.([A-Z][A-Za-z0-9 /&-]{2,40}:)"
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return cleanedText
        }

        let range = NSRange(cleanedText.startIndex..<cleanedText.endIndex, in: cleanedText)
        return expression.stringByReplacingMatches(
            in: cleanedText,
            range: range,
            withTemplate: ".\n$1"
        )
    }

    private func draw(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        lineHeight: CGFloat,
        alignment: NSTextAlignment = .left
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
