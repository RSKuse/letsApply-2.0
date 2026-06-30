//
//  AdminJobTableViewCell.swift
//  letsApply
//

import UIKit

class AdminJobTableViewCell: UITableViewCell {

    static let reuseIdentifier = "AdminJobTableViewCell"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel = makeLabel(
        font: UIFont.systemFont(ofSize: 17, weight: .bold),
        color: .label,
        lines: 2
    )
    private lazy var companyLabel = makeLabel(
        font: UIFont.systemFont(ofSize: 14, weight: .semibold),
        color: AppTheme.secondaryText,
        lines: 1
    )
    private lazy var detailLabel = makeLabel(
        font: UIFont.systemFont(ofSize: 12, weight: .medium),
        color: AppTheme.secondaryText,
        lines: 2
    )

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with job: Job) {
        titleLabel.text = job.title
        companyLabel.text = job.companyName
        detailLabel.text = "\(job.applicationMethod.reviewTitle)\nCloses \(job.closingDateText)"

        let status = job.resolvedPublicationStatus
        statusLabel.text = "  \(status.title.uppercased())  "
        statusLabel.textColor = status.foregroundColor
        statusLabel.backgroundColor = status.backgroundColor
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(companyLabel)
        cardView.addSubview(detailLabel)
        cardView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            statusLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            statusLabel.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -10),

            companyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            companyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            detailLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: companyLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
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
}

private extension JobPublicationStatus {

    var foregroundColor: UIColor {
        switch self {
        case .published:
            return AppTheme.brand
        case .draft:
            return UIColor(red: 0.31, green: 0.42, blue: 0.76, alpha: 1)
        case .paused:
            return UIColor(red: 0.70, green: 0.43, blue: 0.05, alpha: 1)
        case .expired:
            return .systemRed
        }
    }

    var backgroundColor: UIColor {
        foregroundColor.withAlphaComponent(0.12)
    }
}
