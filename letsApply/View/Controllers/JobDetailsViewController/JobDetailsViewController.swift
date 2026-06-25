//
//  JobDetailsViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth

class JobDetailsViewController: UIViewController {

    private let job: Job
    private let firestoreService = FirestoreService()
    private var currentProfile: UserProfile?
    private var isSaved = false
    private var hasApplied = false

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headerCardView,
            quickInfoCardView,
            descriptionSection,
            responsibilitiesSection,
            requirementsSection,
            qualificationsSection,
            experienceSection,
            companySection,
            premiumToolsStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headerCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var companyIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "building.2.fill")
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply Now", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var quickInfoCardView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makeInfoRow(title: "Location", value: job.locationText),
            makeInfoRow(title: "Salary", value: salaryText(for: job)),
            makeInfoRow(title: "Job Type", value: job.jobType),
            makeInfoRow(title: "Remote", value: job.remote ? "Remote friendly" : "On-site"),
            makeInfoRow(title: "Deadline", value: job.application.deadline)
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.backgroundColor = .secondarySystemBackground
        stackView.layer.cornerRadius = 16
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var descriptionSection = makeSection(title: "Description", body: job.description)
    private lazy var responsibilitiesSection = makeSection(title: "Responsibilities", body: bulletText(job.responsibilities, fallback: "Responsibilities will be discussed with the employer."))
    private lazy var requirementsSection = makeSection(title: "Requirements", body: bulletText(job.requirements, fallback: "No specific requirements listed."))
    private lazy var qualificationsSection = makeSection(title: "Qualifications", body: bulletText(job.qualifications, fallback: "No specific qualifications listed."))
    private lazy var experienceSection = makeSection(title: "Experience", body: experienceText(for: job))
    private lazy var companySection = makeSection(title: "Company", body: "\(job.companyName)\n\(job.jobCategory)")

    private lazy var premiumToolsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makePremiumButton(title: "Generate Cover Letter", action: #selector(generateCoverLetterTapped)),
            makePremiumButton(title: "Tailor CV to this Job", action: #selector(tailorCVTapped)),
            makePremiumButton(title: "Improve CV for this Job", action: #selector(improveCVTapped))
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isHidden = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(job: Job) {
        self.job = job
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Job Details"
        setupNavigationBar()
        setupUI()
        configure()
        fetchProfileState()
        fetchSavedState()
        fetchApplicationState()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "bookmark"),
            style: .plain,
            target: self,
            action: #selector(saveTapped)
        )
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(applyButton)
        scrollView.addSubview(contentStackView)

        headerCardView.addSubview(companyIconView)
        headerCardView.addSubview(titleLabel)
        headerCardView.addSubview(companyLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -14),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            companyIconView.topAnchor.constraint(equalTo: headerCardView.topAnchor, constant: 18),
            companyIconView.leadingAnchor.constraint(equalTo: headerCardView.leadingAnchor, constant: 18),
            companyIconView.widthAnchor.constraint(equalToConstant: 64),
            companyIconView.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: companyIconView.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: headerCardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: headerCardView.trailingAnchor, constant: -18),

            companyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            companyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            companyLabel.bottomAnchor.constraint(equalTo: headerCardView.bottomAnchor, constant: -18),

            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            applyButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func configure() {
        titleLabel.text = job.title
        companyLabel.text = "\(job.companyName)\n\(job.locationText)"
    }

    private func fetchProfileState() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            premiumToolsStackView.isHidden = true
            return
        }

        firestoreService.fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .success(let profile) = result {
                    self.currentProfile = profile
                    self.premiumToolsStackView.isHidden = !profile.isPremium
                }
            }
        }
    }

    private func fetchSavedState() {
        guard let user = Auth.auth().currentUser,
              !user.isAnonymous,
              let jobId = job.id else {
            updateSavedButton()
            return
        }

        firestoreService.isJobSaved(userId: user.uid, jobId: jobId) { [weak self] saved in
            DispatchQueue.main.async {
                self?.isSaved = saved
                self?.updateSavedButton()
            }
        }
    }

    private func fetchApplicationState() {
        guard let user = Auth.auth().currentUser,
              !user.isAnonymous,
              let jobId = job.id else {
            updateApplyButton()
            return
        }

        firestoreService.hasApplied(userId: user.uid, jobId: jobId) { [weak self] applied in
            DispatchQueue.main.async {
                self?.hasApplied = applied
                self?.updateApplyButton()
            }
        }
    }

    private func updateApplyButton() {
        if hasApplied {
            applyButton.setTitle("Application Submitted", for: .normal)
            applyButton.backgroundColor = .systemGray
            applyButton.isEnabled = false
        } else {
            applyButton.setTitle("Apply Now", for: .normal)
            applyButton.backgroundColor = .systemGreen
            applyButton.isEnabled = true
        }
    }

    private func updateSavedButton() {
        let imageName = isSaved ? "bookmark.fill" : "bookmark"
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: imageName)
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        return row
    }

    private func makeSection(title: String, body: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .label

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping

        let stackView = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.backgroundColor = .secondarySystemBackground
        stackView.layer.cornerRadius = 16
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }

    private func makePremiumButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.10)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func salaryText(for job: Job) -> String {
        let salary = job.compensation.salaryRange
        if salary.min == 0 && salary.max == 0 {
            return "Salary not disclosed"
        }
        return "\(salary.currency) \(salary.min) to \(salary.max)"
    }

    private func bulletText(_ items: [String], fallback: String) -> String {
        guard !items.isEmpty else { return fallback }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private func experienceText(for job: Job) -> String {
        let years = "\(job.experience.minYears)-\(job.experience.preferredYears) years"
        if job.experience.details.isEmpty {
            return years
        }
        return "\(years)\n\(job.experience.details)"
    }

    @objc private func applyTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        firestoreService.fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let profile):
                    self.currentProfile = profile
                    guard profile.isComplete else {
                        self.showProfileCompletionPrompt()
                        return
                    }

                    guard profile.cvUrl != nil else {
                        self.showMissingCVPrompt(profile: profile)
                        return
                    }

                    self.submitApplication(profile: profile)
                case .failure(let error):
                    self.showAlert(title: "Profile Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func submitApplication(profile: UserProfile) {
        applyButton.isEnabled = false

        firestoreService.createApplication(userProfile: profile, job: job) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.applyButton.isEnabled = true

                switch result {
                case .success:
                    self.hasApplied = true
                    self.updateApplyButton()
                    self.showAlert(title: "Application Submitted", message: "Your application for \(self.job.title) has been submitted.")
                case .failure(let error):
                    self.showAlert(title: "Application Not Submitted", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func saveTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt(message: "Create your profile to save this job.")
            return
        }

        guard let jobId = job.id else {
            showAlert(title: "Save Failed", message: "This job is missing an ID.")
            return
        }

        if isSaved {
            firestoreService.removeSavedJob(userId: user.uid, jobId: jobId) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Save Failed", message: error.localizedDescription)
                    } else {
                        self?.isSaved = false
                        self?.updateSavedButton()
                    }
                }
            }
        } else {
            firestoreService.saveJob(userId: user.uid, job: job) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Save Failed", message: error.localizedDescription)
                    } else {
                        self?.isSaved = true
                        self?.updateSavedButton()
                    }
                }
            }
        }
    }

    @objc private func generateCoverLetterTapped() {
        openAITool(.coverLetter)
    }

    @objc private func tailorCVTapped() {
        openAITool(.tailorCV)
    }

    @objc private func improveCVTapped() {
        openAITool(.improveCV)
    }

    private func openAITool(_ tool: AICareerService.CareerTool) {
        guard let profile = currentProfile else {
            showAlert(title: "Profile Needed", message: "Load or complete your profile before using premium AI tools.")
            return
        }

        let aiVC = AICareerToolViewController(tool: tool, userProfile: profile, job: job)
        aiVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(aiVC, animated: true)
    }

    private func showRegistrationPrompt(message: String = "Create your profile to apply for this job.") {
        let alert = UIAlertController(title: "Create Profile", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Register", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(SignUpViewController(), animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showMissingCVPrompt(profile: UserProfile) {
        let alert = UIAlertController(
            title: "Add a CV",
            message: "A CV makes this application stronger. You can upload one now or apply without it.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Upload CV", style: .default) { [weak self] _ in
            let cvVC = CVBuilderViewController()
            cvVC.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(cvVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Apply Without CV", style: .default) { [weak self] _ in
            self?.submitApplication(profile: profile)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showProfileCompletionPrompt() {
        let alert = UIAlertController(
            title: "Complete Profile",
            message: "Complete your profile before applying for this job.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Complete Profile", style: .default) { [weak self] _ in
            let profileVC = ProfileViewController()
            profileVC.isProfileSetupMode = true
            self?.navigationController?.pushViewController(profileVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
