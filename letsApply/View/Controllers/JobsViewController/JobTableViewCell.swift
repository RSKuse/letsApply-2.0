//
//  JobTableViewCell.swift
//  letsApply
//


import UIKit

class JobTableViewCell: UITableViewCell {

    static let reuseIdentifier = "JobTableViewCellID"

    lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var jobIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "building.2.fill")
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.10)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            jobTitleLabel,
            salaryLabel,
            companyLabel,
            locationLabel
        ])
        stack.axis = .vertical
        stack.spacing = 5
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        contentView.addSubview(textStackView)
        contentView.addSubview(jobIconView)


        textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        textStackView.trailingAnchor.constraint(equalTo: jobIconView.leadingAnchor, constant: -16).isActive = true
        textStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12).isActive = true

        jobIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        jobIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        jobIconView.widthAnchor.constraint(equalToConstant: 82).isActive = true
        jobIconView.heightAnchor.constraint(equalToConstant: 82).isActive = true

    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title

        let currency = job.compensation.salaryRange.currency
        let min = job.compensation.salaryRange.min
        let max = job.compensation.salaryRange.max

        if min == 0 && max == 0 {
            salaryLabel.text = "Salary not disclosed"
        } else {
            salaryLabel.text = "\(currency) \(min) to \(max)"
        }

        companyLabel.text = job.companyName
        locationLabel.text = "\(job.location.city), \(job.location.region)"
    }
}
