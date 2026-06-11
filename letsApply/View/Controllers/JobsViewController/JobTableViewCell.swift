//
//  JobTableViewCell.swift
//  letsApply
//

import UIKit

class JobTableViewCell: UITableViewCell {

    static let reuseIdentifier = "JobTableViewCellID"

    lazy var jobTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Job Title"
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Salary"
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var jobDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Job description"
        label.font = UIFont.systemFont(ofSize: 14, weight: .light)
        label.textColor = .systemGray
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var companyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "job_placeholder") ?? UIImage(systemName: "building.2.fill")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var jobInformationStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [jobTitleLabel, salaryLabel, jobDescriptionLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 3
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(companyImageView)
        contentView.addSubview(jobInformationStackView)

        NSLayoutConstraint.activate([
            companyImageView.heightAnchor.constraint(equalToConstant: 82),
            companyImageView.widthAnchor.constraint(equalToConstant: 82),
            companyImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            companyImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            jobInformationStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            jobInformationStackView.rightAnchor.constraint(equalTo: companyImageView.leftAnchor, constant: -20),
            jobInformationStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            jobInformationStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with job: Job) {
        jobTitleLabel.text = job.title

        let currency = job.compensation.salaryRange.currency
        let min = job.compensation.salaryRange.min
        let max = job.compensation.salaryRange.max

        if min == 0 && max == 0 {
            salaryLabel.text = "Salary not specified"
        } else {
            salaryLabel.text = "\(currency) \(min) to \(max)"
        }

        let location = [job.location.city, job.location.region].filter { !$0.isEmpty }.joined(separator: ", ")
        jobDescriptionLabel.text = "\(job.companyName)\n\(location)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
