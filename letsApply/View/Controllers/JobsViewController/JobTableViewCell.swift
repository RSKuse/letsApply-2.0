//
//  JobTableViewCell.swift
//  letsApply
//

import UIKit

class JobTableViewCell: UITableViewCell {

    static let reuseIdentifier = "JobTableViewCellID"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = AppTheme.brand
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var jobIconView: CompanyLogoView = {
        let view = CompanyLogoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        jobIconView.reset()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppTheme.background
        contentView.backgroundColor = AppTheme.background

        contentView.addSubview(cardView)
        cardView.addSubview(jobTitleLabel)
        cardView.addSubview(companyLabel)
        cardView.addSubview(detailLabel)
        cardView.addSubview(salaryLabel)
        cardView.addSubview(jobIconView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            jobIconView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            jobIconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            jobIconView.widthAnchor.constraint(equalToConstant: 62),
            jobIconView.heightAnchor.constraint(equalToConstant: 62),

            jobTitleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            jobTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            jobTitleLabel.trailingAnchor.constraint(equalTo: jobIconView.leadingAnchor, constant: -14),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 4),
            companyLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),

            detailLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 5),
            detailLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),

            salaryLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            salaryLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),
            salaryLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with job: Job) {
        jobIconView.configure(with: job)
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        detailLabel.text = "\(job.location.city)  |  \(job.jobType)"
        salaryLabel.text = job.salaryText
    }
}
