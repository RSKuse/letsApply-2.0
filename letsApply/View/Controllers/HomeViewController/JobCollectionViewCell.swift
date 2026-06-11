//
//  JobCollectionViewCell.swift
//  letsApply
//

import UIKit

class JobCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "JobCollectionViewCellID"

    private lazy var jobImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "design_boom") ?? UIImage(systemName: "briefcase.fill")
        imageView.tintColor = .systemGreen
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Job Title"
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.text = "Company"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(jobImageView)
        contentView.addSubview(jobTitleLabel)
        contentView.addSubview(companyLabel)
        contentView.addSubview(locationLabel)

        NSLayoutConstraint.activate([
            jobImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            jobImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            jobImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            jobImageView.heightAnchor.constraint(equalToConstant: 130),

            jobTitleLabel.topAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: 8),
            jobTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            jobTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 4),
            companyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            locationLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 3),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        locationLabel.text = [job.location.city, job.location.region].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
