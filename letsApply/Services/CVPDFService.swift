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

private final class CVPDFWriter {

    private let context: UIGraphicsPDFRendererContext
    private let pageBounds: CGRect
    private let profile: UserProfile
    private let margin: CGFloat = 44
    private let bottomLimit: CGFloat = 742
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
            title: "PROFESSIONAL PROFILE",
            text: profile.professionalSummary,
            fallback: "Professional profile available on request."
        )
        drawInlineListSection(title: "CORE SKILLS", items: profile.skills)
        drawSection(title: "EDUCATION", text: profile.education)
        drawListSection(title: "QUALIFICATIONS", items: profile.qualifications)
        drawSection(title: "EXPERIENCE", text: profile.experience)
    }

    private func startPage(isFirstPage: Bool) {
        context.beginPage()
        pageNumber += 1

        if isFirstPage {
            drawFirstPageHeader()
            currentY = 190
        } else {
            drawContinuationHeader()
            currentY = 78
        }

        drawFooter()
    }

    private func drawFirstPageHeader() {
        inkColor.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: pageBounds.width, height: 162))

        brandColor.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 162))

        draw(
            profile.name.uppercased(),
            in: CGRect(x: margin, y: 34, width: pageBounds.width - (margin * 2), height: 38),
            font: UIFont.systemFont(ofSize: 26, weight: .bold),
            color: .white,
            lineHeight: 30
        )

        let jobTitle = profile.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        draw(
            jobTitle.isEmpty ? "PROFESSIONAL CANDIDATE" : jobTitle.uppercased(),
            in: CGRect(x: margin, y: 76, width: pageBounds.width - (margin * 2), height: 24),
            font: UIFont.systemFont(ofSize: 13, weight: .bold),
            color: accentColor,
            lineHeight: 18
        )

        let contactLine = [profile.email, profile.location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "  |  ")

        draw(
            contactLine,
            in: CGRect(x: margin, y: 116, width: pageBounds.width - (margin * 2), height: 24),
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
        currentY += 6
    }

    private func drawSectionTitle(_ title: String) {
        sectionColor.setFill()
        context.cgContext.fill(
            CGRect(x: margin, y: currentY, width: pageBounds.width - (margin * 2), height: 30)
        )

        brandColor.setFill()
        context.cgContext.fill(CGRect(x: margin, y: currentY, width: 5, height: 30))

        draw(
            title,
            in: CGRect(
                x: margin + 16,
                y: currentY + 7,
                width: pageBounds.width - (margin * 2) - 24,
                height: 18
            ),
            font: UIFont.systemFont(ofSize: 12, weight: .bold),
            color: inkColor,
            lineHeight: 15
        )

        currentY += 38
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
            if bottomLimit - currentY < 34 {
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

            currentY += ceil(height) + 5
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 16
        paragraphStyle.maximumLineHeight = 16

        return (text as NSString).boundingRect(
            with: CGSize(width: pageBounds.width - (margin * 2), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: bodyFont,
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
