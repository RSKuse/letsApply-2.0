//
//  JobDetailsViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth

class JobDetailsViewController: UIViewController {

    private let job: Job
    private let isPreviewMode: Bool
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
            applicationSection,
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
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var companyIconView: CompanyLogoView = {
        let view = CompanyLogoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Review Application",
            systemImageName: "arrow.right"
        )
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
            makeInfoRow(title: "Deadline", value: job.closingDateText),
            makeInfoRow(title: "Application", value: job.applicationRoute.title),
            makeInfoRow(
                title: "Source",
                value: job.verified ? "\(job.sourceName) · Verified" : job.sourceName
            )
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.backgroundColor = AppTheme.surface
        stackView.layer.cornerRadius = AppTheme.cardRadius
        stackView.layer.borderColor = AppTheme.border.cgColor
        stackView.layer.borderWidth = 1
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
    private lazy var applicationSection = makeApplicationSection()
    private lazy var companySection = makeSection(title: "Company", body: "\(job.companyName)\n\(job.jobCategory)")

    private lazy var premiumToolsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makePremiumButton(title: "Auto Apply Assistant", action: #selector(autoApplyAssistantTapped)),
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

    init(job: Job, isPreviewMode: Bool = false) {
        self.job = job
        self.isPreviewMode = isPreviewMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = isPreviewMode ? "Vacancy Preview" : "Job Details"
        setupNavigationBar()
        setupUI()
        configure()

        if isPreviewMode {
            configurePreviewMode()
            return
        }

        fetchProfileState()
        fetchSavedState()
        fetchApplicationState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        guard ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_JOB_SECTION"]
                == "application" else {
            return
        }
        view.layoutIfNeeded()
        let targetY = max(0, applicationSection.frame.minY - 12)
        scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        #endif
    }

    private func setupNavigationBar() {
        guard !isPreviewMode else { return }
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
        companyIconView.configure(with: job)
        titleLabel.text = job.title
        companyLabel.text = "\(job.companyName)\n\(job.locationText)"
    }

    private func configurePreviewMode() {
        applyButton.configuration?.title = "Preview Only"
        applyButton.configuration?.image = UIImage(systemName: "eye")
        applyButton.configuration?.baseBackgroundColor = .systemGray
        applyButton.isEnabled = false
        premiumToolsStackView.isHidden = true
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
            applyButton.configuration?.title = "Application Submitted"
            applyButton.configuration?.image = UIImage(systemName: "checkmark")
            applyButton.configuration?.baseBackgroundColor = .systemGray
            applyButton.isEnabled = false
        } else {
            applyButton.configuration?.title = job.applicationRoute.actionTitle
            applyButton.configuration?.image = UIImage(systemName: "arrow.right")
            applyButton.configuration?.baseBackgroundColor = AppTheme.brand
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
        stackView.backgroundColor = AppTheme.surface
        stackView.layer.cornerRadius = AppTheme.cardRadius
        stackView.layer.borderColor = AppTheme.border.cgColor
        stackView.layer.borderWidth = 1
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }

    private func makeApplicationSection() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "How to Apply"
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .label

        let methodLabel = applicationDetailLabel(
            title: "Method",
            value: job.applicationRoute.title
        )
        let referenceLabel = applicationDetailLabel(
            title: "Reference",
            value: job.application.referenceNumber
        )
        referenceLabel.isHidden = job.application.referenceNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let emailLabel = applicationDetailLabel(
            title: "Application email",
            value: job.application.applicationEmail
        )
        emailLabel.isHidden = job.application.applicationEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let copyEmailButton = applicationActionButton(
            title: "Copy application email",
            imageName: "doc.on.doc",
            action: #selector(copyApplicationEmailTapped)
        )
        copyEmailButton.isHidden = emailLabel.isHidden

        let websiteLabel = applicationDetailLabel(
            title: "Application website",
            value: job.application.applicationUrl
        )
        websiteLabel.isHidden = job.application.applicationUrl
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let openWebsiteButton = applicationActionButton(
            title: "Open application website",
            imageName: "safari",
            action: #selector(openApplicationWebsiteTapped)
        )
        openWebsiteButton.isHidden = websiteLabel.isHidden

        let instructions = job.application.applicationInstructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let instructionsLabel = applicationDetailLabel(
            title: "Official instructions",
            value: instructions
        )
        instructionsLabel.isHidden = instructions.isEmpty

        let copyInstructionsButton = applicationActionButton(
            title: "Copy application instructions",
            imageName: "doc.on.doc",
            action: #selector(copyApplicationInstructionsTapped)
        )
        copyInstructionsButton.isHidden = instructions.isEmpty

        let sourceButton = applicationActionButton(
            title: "View official vacancy source",
            imageName: "link",
            action: #selector(openSourceTapped)
        )
        sourceButton.isHidden = job.sourceUrl
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            methodLabel,
            referenceLabel,
            emailLabel,
            copyEmailButton,
            websiteLabel,
            openWebsiteButton,
            instructionsLabel,
            copyInstructionsButton,
            sourceButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.backgroundColor = AppTheme.surface
        stackView.layer.cornerRadius = AppTheme.cardRadius
        stackView.layer.borderColor = AppTheme.border.cgColor
        stackView.layer.borderWidth = 1
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }

    private func applicationDetailLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        label.text = "\(title)\n\(value)"
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }

    private func applicationActionButton(
        title: String,
        imageName: String,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makePremiumButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: "sparkles")
        configuration.imagePadding = 10
        configuration.baseBackgroundColor = AppTheme.mutedSurface
        configuration.baseForegroundColor = AppTheme.brand
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func salaryText(for job: Job) -> String {
        job.salaryText
    }

    private func bulletText(_ items: [String], fallback: String) -> String {
        guard !items.isEmpty else { return fallback }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private func experienceText(for job: Job) -> String {
        let details = job.experience.details
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let minimum = job.experience.minYears
        let preferred = job.experience.preferredYears

        if minimum <= 0, preferred <= 0 {
            return details.isEmpty
                ? "See the official requirements for experience details."
                : details
        }

        let years: String
        if minimum == preferred || preferred <= 0 {
            years = "\(minimum) \(minimum == 1 ? "year" : "years") required"
        } else {
            years = "\(minimum)-\(preferred) years"
        }
        return details.isEmpty ? years : "\(years)\n\(details)"
    }

    @objc private func copyApplicationEmailTapped() {
        let email = job.application.applicationEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        UIPasteboard.general.string = email
        showAlert(
            title: "Email Copied",
            message: "\(email) is ready to paste into Mail or Gmail."
        )
    }

    @objc private func copyApplicationInstructionsTapped() {
        let instructions = job.application.applicationInstructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instructions.isEmpty else { return }
        UIPasteboard.general.string = instructions
        showAlert(
            title: "Instructions Copied",
            message: "The official application instructions are ready to paste."
        )
    }

    @objc private func openApplicationWebsiteTapped() {
        openURL(job.application.applicationUrl, missingTitle: "Application Website Missing")
    }

    @objc private func openSourceTapped() {
        openURL(job.sourceUrl, missingTitle: "Vacancy Source Missing")
    }

    private func openURL(_ value: String, missingTitle: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased().hasPrefix("http")
            ? trimmed
            : "https://\(trimmed)"
        guard let url = URL(string: normalized), !trimmed.isEmpty else {
            showAlert(
                title: missingTitle,
                message: "This vacancy does not contain a valid web address."
            )
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func applyTapped() {
        guard !hasApplied else {
            showAlert(title: "Already Applied", message: "Your application for this job has already been submitted.")
            return
        }

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
                        self.showProfileCompletionPrompt(missingFields: profile.missingRequiredFields)
                        return
                    }

                    self.openApplicationPackageReview(profile: profile)
                case .failure(let error):
                    self.showAlert(title: "Profile Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func openApplicationPackageReview(profile: UserProfile) {
        let reviewVC = AutoApplyAssistantViewController(job: job, userProfile: profile)
        reviewVC.hidesBottomBarWhenPushed = true
        reviewVC.onApplicationSubmitted = { [weak self] in
            self?.hasApplied = true
            self?.updateApplyButton()
        }
        navigationController?.pushViewController(reviewVC, animated: true)
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

    @objc private func autoApplyAssistantTapped() {
        guard let profile = currentProfile else {
            showAlert(title: "Profile Needed", message: "Load or complete your profile before using the Auto Apply Assistant.")
            return
        }

        guard profile.isComplete else {
            showProfileCompletionPrompt(missingFields: profile.missingRequiredFields)
            return
        }

        let autoApplyVC = AutoApplyAssistantViewController(job: job, userProfile: profile)
        autoApplyVC.hidesBottomBarWhenPushed = true
        autoApplyVC.onApplicationSubmitted = { [weak self] in
            self?.hasApplied = true
            self?.updateApplyButton()
        }
        navigationController?.pushViewController(autoApplyVC, animated: true)
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

    private func showProfileCompletionPrompt(missingFields: [String]) {
        let missingText = missingFields.isEmpty ? "" : "\n\nMissing: \(missingFields.joined(separator: ", "))"
        let alert = UIAlertController(
            title: "Complete Profile",
            message: "Complete your profile before applying for this job.\(missingText)",
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
