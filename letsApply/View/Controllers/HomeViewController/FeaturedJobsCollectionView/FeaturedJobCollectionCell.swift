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





/*import UIKit

class FeaturedJobCollectionCell: UICollectionViewCell {

    static let reuseIdentifier = "FeaturedJobCollectionCellID"

    private lazy var jobImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "abc_news") ?? UIImage(systemName: "building.2.fill")
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

    private lazy var mostAppliedView: MostAppliedView = {
        let view = MostAppliedView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupView()
    }

    private func setupView() {
        contentView.addSubview(jobImageView)
        jobImageView.addSubview(mostAppliedView)
        contentView.addSubview(jobTitleLabel)
        contentView.addSubview(companyLabel)

        NSLayoutConstraint.activate([
            jobImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            jobImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            jobImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            jobImageView.heightAnchor.constraint(equalToConstant: 130),

            mostAppliedView.leftAnchor.constraint(equalTo: jobImageView.leftAnchor),
            mostAppliedView.bottomAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: -8),
            mostAppliedView.heightAnchor.constraint(equalToConstant: 20),

            jobTitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            jobTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -6),
            jobTitleLabel.topAnchor.constraint(equalTo: jobImageView.bottomAnchor, constant: 8),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 4),
            companyLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
            companyLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor)
        ])
    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title
        companyLabel.text = job.companyName
        mostAppliedView.isHidden = !job.isFeatured
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}*/
