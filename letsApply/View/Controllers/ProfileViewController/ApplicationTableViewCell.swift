//
//  ApplicationTableViewCell.swift
//  letsApply
//

import UIKit

class ApplicationTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ApplicationTableViewCellID"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
        imageView.tintColor = AppTheme.brand
        imageView.backgroundColor = AppTheme.mutedSurface
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = AppTheme.cardRadius
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel = makeLabel(font: UIFont.systemFont(ofSize: 16, weight: .bold), color: .label, lines: 2)
    private lazy var companyLabel = makeLabel(font: UIFont.systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabel, lines: 1)
    private lazy var dateLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .medium), color: .secondaryLabel, lines: 1)

    private lazy var statusLabel: UILabel = {
        let label = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .bold), color: AppTheme.brand, lines: 1)
        label.textAlignment = .center
        label.backgroundColor = AppTheme.mutedSurface
        label.layer.cornerRadius = AppTheme.cardRadius
        label.clipsToBounds = true
        return label
    }()

    private lazy var cvLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .semibold), color: .secondaryLabel, lines: 1)
    private lazy var detailsLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .semibold), color: AppTheme.brand, lines: 2)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(companyLabel)
        cardView.addSubview(dateLabel)
        cardView.addSubview(statusLabel)
        cardView.addSubview(cvLabel)
        cardView.addSubview(detailsLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            statusLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 92),
            statusLabel.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -10),

            companyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            companyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            dateLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            cvLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            cvLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            cvLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            detailsLabel.topAnchor.constraint(equalTo: cvLabel.bottomAnchor, constant: 6),
            detailsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            detailsLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    private func makeLabel(font: UIFont, color: UIColor, lines: Int) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func configure(with application: Application) {
        titleLabel.text = application.jobTitle
        companyLabel.text = application.companyName
        dateLabel.text = "\(datePrefix(for: application.status)) \(formattedDate(application.appliedDate))"
        configureStatus(application.status)
        cvLabel.text = application.cvUrl == nil ? "Profile CV draft used" : "CV attached"
        detailsLabel.text = applicationDetailsText(for: application)
    }

    private func configureStatus(_ status: String) {
        let normalized = status.lowercased()
        let isSubmitted = ["submitted", "sent", "applied-by-email", "applied-externally"]
            .contains(normalized)

        statusLabel.text = statusDisplayText(normalized)
        statusLabel.textColor = isSubmitted ? AppTheme.brand : UIColor.systemOrange
        statusLabel.backgroundColor = isSubmitted
            ? AppTheme.mutedSurface
            : UIColor.systemOrange.withAlphaComponent(0.12)
        iconView.image = UIImage(
            systemName: isSubmitted ? "paperplane.fill" : "doc.badge.clock.fill"
        )
    }

    private func statusDisplayText(_ status: String) -> String {
        switch status {
        case "ready-to-submit":
            return "Continue"
        case "requires-manual-action":
            return "Action Needed"
        case "email-draft":
            return "Email Draft"
        case "submitted", "sent":
            return "Submitted"
        default:
            return status
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
    }

    private func datePrefix(for status: String) -> String {
        switch status.lowercased() {
        case "submitted", "sent", "applied-by-email", "applied-externally":
            return "Applied"
        default:
            return "Prepared"
        }
    }

    private func applicationDetailsText(for application: Application) -> String {
        guard application.isAIGenerated == true else {
            return "Standard application"
        }

        if let matchScore = application.matchScore {
            let method = applicationMethodDisplay(application.applicationMethod)
            return "\(method) application · \(matchScore)% match"
        }

        return "AI-assisted application"
    }

    private func applicationMethodDisplay(_ method: String?) -> String {
        switch method {
        case JobApplicationMethod.email.rawValue:
            return "Email"
        case JobApplicationMethod.externalWebsite.rawValue, JobApplicationRoute.externalPortal.rawValue:
            return "Employer website"
        case JobApplicationMethod.governmentEmail.rawValue:
            return "Government email"
        case JobApplicationMethod.governmentWebsite.rawValue:
            return "Government website"
        case JobApplicationMethod.governmentManual.rawValue, JobApplicationMethod.pdfCircular.rawValue:
            return "Government"
        case JobApplicationRoute.requiredForm.rawValue:
            return "Required form"
        case JobApplicationMethod.manualInstruction.rawValue, JobApplicationRoute.manual.rawValue:
            return "Manual"
        case JobApplicationMethod.internalApply.rawValue, JobApplicationRoute.inApp.rawValue:
            return "In-app"
        default:
            return "Application"
        }
    }

    private func formattedDate(_ dateText: String) -> String {
        let isoFormatter = ISO8601DateFormatter()

        guard let date = isoFormatter.date(from: dateText) else {
            return dateText
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}
