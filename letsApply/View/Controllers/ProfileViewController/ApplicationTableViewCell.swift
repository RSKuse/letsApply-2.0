//
//  ApplicationTableViewCell.swift
//  letsApply
//

import UIKit

class ApplicationTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ApplicationTableViewCellID"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "paperplane.fill"))
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel = makeLabel(font: UIFont.systemFont(ofSize: 16, weight: .bold), color: .label, lines: 2)
    private lazy var companyLabel = makeLabel(font: UIFont.systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabel, lines: 1)
    private lazy var dateLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .medium), color: .secondaryLabel, lines: 1)

    private lazy var statusLabel: UILabel = {
        let label = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .bold), color: .systemGreen, lines: 1)
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private lazy var cvLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .semibold), color: .secondaryLabel, lines: 1)
    private lazy var packageLabel = makeLabel(font: UIFont.systemFont(ofSize: 12, weight: .semibold), color: .systemGreen, lines: 1)

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
        cardView.addSubview(packageLabel)

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

            packageLabel.topAnchor.constraint(equalTo: cvLabel.bottomAnchor, constant: 6),
            packageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            packageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            packageLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16)
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
        dateLabel.text = "Applied \(formattedDate(application.appliedDate))"
        statusLabel.text = application.status.capitalized
        cvLabel.text = application.cvUrl == nil ? "Profile CV draft used" : "CV attached"
        packageLabel.text = packageText(for: application)
    }

    private func packageText(for application: Application) -> String {
        guard application.isAIGenerated == true else {
            return "Standard application"
        }

        if let matchScore = application.matchScore {
            return "Smart package - \(matchScore)% match"
        }

        return "Smart package submitted"
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
