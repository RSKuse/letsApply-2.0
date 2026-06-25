//
//  JobCollectionViewCell.swift
//  letsApply
//

import UIKit

class JobCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "JobCollectionViewCellID"

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var companyIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "building.2.fill")
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 14
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var jobTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .right
        label.numberOfLines = 1
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
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(companyIconView)
        cardView.addSubview(jobTypeLabel)
        cardView.addSubview(jobTitleLabel)
        cardView.addSubview(companyLabel)
        cardView.addSubview(locationLabel)
        cardView.addSubview(salaryLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            companyIconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            companyIconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            companyIconView.widthAnchor.constraint(equalToConstant: 46),
            companyIconView.heightAnchor.constraint(equalToConstant: 46),

            jobTypeLabel.centerYAnchor.constraint(equalTo: companyIconView.centerYAnchor),
            jobTypeLabel.leadingAnchor.constraint(equalTo: companyIconView.trailingAnchor, constant: 8),
            jobTypeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            jobTitleLabel.topAnchor.constraint(equalTo: companyIconView.bottomAnchor, constant: 16),
            jobTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            jobTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 8),
            companyLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),

            locationLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),

            salaryLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            salaryLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),
            salaryLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        locationLabel.text = job.locationText
        salaryLabel.text = job.salaryText
        jobTypeLabel.text = job.remote ? "Remote" : job.jobType
    }
}
