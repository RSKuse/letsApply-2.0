//
//  JobDetailsViewController.swift
//  letsApply
//

import UIKit

class JobDetailsViewController: UIViewController {

    private let job: Job

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "job_placeholder") ?? UIImage(systemName: "building.2.fill")
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = .systemGray6
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var salaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemGreen
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply Now", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(job: Job) {
        self.job = job
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Job Details"
        setupUI()
        configure()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(applyButton)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(companyLabel)
        contentView.addSubview(salaryLabel)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -16),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 260),

            titleLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            companyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            companyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            salaryLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 12),
            salaryLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            salaryLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: salaryLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),

            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            applyButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configure() {
        titleLabel.text = job.title
        companyLabel.text = "\(job.companyName) • \([job.location.city, job.location.region, job.location.country].filter { !$0.isEmpty }.joined(separator: ", "))"

        let salary = job.compensation.salaryRange
        if salary.min == 0 && salary.max == 0 {
            salaryLabel.text = "Salary not specified"
        } else {
            salaryLabel.text = "\(salary.currency) \(salary.min) to \(salary.max)"
        }

        let requirements = job.requirements.isEmpty ? "No specific requirements listed." : job.requirements.map { "• \($0)" }.joined(separator: "\n")
        let responsibilities = job.responsibilities.isEmpty ? "Responsibilities will be discussed with the employer." : job.responsibilities.map { "• \($0)" }.joined(separator: "\n")

        descriptionLabel.text = """
        \(job.description)

        Job Type
        \(job.jobType)

        Requirements
        \(requirements)

        Responsibilities
        \(responsibilities)

        Application Deadline
        \(job.application.deadline)
        """
    }

    @objc private func applyTapped() {
        let alert = UIAlertController(
            title: "Application Started",
            message: "You are applying for \(job.title) at \(job.companyName).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
