//
//  JobCollectionViewCell.swift
//  letsApply
//

import UIKit

class JobCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "JobCollectionViewCellID"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var companyIconView: CompanyLogoView = {
        let view = CompanyLogoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var jobTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = AppTheme.brand
        label.textAlignment = .right
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var headerTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [jobTitleLabel, companyLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var footerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [salaryLabel, jobTypeLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        companyIconView.reset()
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(companyIconView)
        cardView.addSubview(headerTextStackView)
        cardView.addSubview(locationLabel)
        cardView.addSubview(footerStackView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            companyIconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            companyIconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            companyIconView.widthAnchor.constraint(equalToConstant: 48),
            companyIconView.heightAnchor.constraint(equalToConstant: 48),

            headerTextStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            headerTextStackView.leadingAnchor.constraint(equalTo: companyIconView.trailingAnchor, constant: 12),
            headerTextStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            locationLabel.topAnchor.constraint(equalTo: headerTextStackView.bottomAnchor, constant: 10),
            locationLabel.topAnchor.constraint(greaterThanOrEqualTo: companyIconView.bottomAnchor, constant: 10),
            locationLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            locationLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            footerStackView.leadingAnchor.constraint(equalTo: locationLabel.leadingAnchor),
            footerStackView.trailingAnchor.constraint(equalTo: locationLabel.trailingAnchor),
            footerStackView.topAnchor.constraint(greaterThanOrEqualTo: locationLabel.bottomAnchor, constant: 12),
            footerStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func configure(with job: Job) {
        companyIconView.configure(with: job)
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        locationLabel.text = job.locationText
        salaryLabel.text = job.salaryText
        jobTypeLabel.text = job.remote ? "Remote" : job.jobType
    }
}
