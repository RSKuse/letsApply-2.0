//
//  FeaturedJobCollectionCell.swift
//  letsApply
//

import UIKit

class FeaturedJobCollectionCell: UICollectionViewCell {

    static let reuseIdentifier = "FeaturedJobCollectionCellID"

    private lazy var jobImageView: CompanyLogoView = {
        let view = CompanyLogoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var featuredBadge: UILabel = {
        let label = UILabel()
        label.text = "FEATURED"
        label.textColor = .white
        label.backgroundColor = AppTheme.brand
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
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
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = AppTheme.brand
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        jobImageView.reset()
    }

    private func setupUI() {
        contentView.backgroundColor = AppTheme.surface
        contentView.layer.cornerRadius = AppTheme.cardRadius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppTheme.border.cgColor
        contentView.clipsToBounds = true

        contentView.addSubview(jobImageView)
        contentView.addSubview(featuredBadge)
        contentView.addSubview(jobTitleLabel)
        contentView.addSubview(companyLabel)
        contentView.addSubview(salaryLabel)

        NSLayoutConstraint.activate([
            jobImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            jobImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            jobImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            jobImageView.heightAnchor.constraint(equalToConstant: 86),

            featuredBadge.leadingAnchor.constraint(equalTo: jobImageView.leadingAnchor, constant: 8),
            featuredBadge.bottomAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: -8),
            featuredBadge.widthAnchor.constraint(equalToConstant: 72),
            featuredBadge.heightAnchor.constraint(equalToConstant: 22),

            jobTitleLabel.topAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: 10),
            jobTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            jobTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 5),
            companyLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),

            salaryLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            salaryLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),
            salaryLabel.topAnchor.constraint(greaterThanOrEqualTo: companyLabel.bottomAnchor, constant: 6),
            salaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with job: Job) {
        jobImageView.configure(with: job)
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        salaryLabel.text = job.salaryText
    }
}
