//
//  FeaturedJobCollectionCell.swift
//  letsApply
//


import UIKit

class FeaturedJobCollectionCell: UICollectionViewCell {

    static let reuseIdentifier = "FeaturedJobCollectionCellID"

    lazy var jobImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "briefcase.fill")
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var featuredBadge: UILabel = {
        let label = UILabel()
        label.text = "Featured"
        label.textColor = .white
        label.backgroundColor = .systemGreen
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 1
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

    private func setupUI() {
        contentView.backgroundColor = .white

        contentView.addSubview(jobImageView)
        contentView.addSubview(featuredBadge)
        contentView.addSubview(jobTitleLabel)
        contentView.addSubview(companyLabel)


        jobImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        jobImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        jobImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        jobImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        featuredBadge.leadingAnchor.constraint(equalTo: jobImageView.leadingAnchor, constant: 8).isActive = true
        featuredBadge.bottomAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: -8).isActive = true
        featuredBadge.widthAnchor.constraint(equalToConstant: 78).isActive = true
        featuredBadge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        jobTitleLabel.topAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: 10).isActive = true
        jobTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        jobTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

        companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 4).isActive = true
        companyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        companyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true

    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
    }
}
