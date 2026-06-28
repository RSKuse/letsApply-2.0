//
//  AutoApplyAssistantViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth
import MessageUI
import SafariServices

class AutoApplyAssistantViewController: UIViewController {

    var onApplicationSubmitted: (() -> Void)?

    private let job: Job
    private let userProfile: UserProfile
    private let aiCareerService = AICareerService()
    private let firestoreService = FirestoreService()
    private let pdfService = CVPDFService()
    private var autoApplyPackage: AutoApplyPackage?
    private var isSubmitting = false

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            jobCardView,
            routeCardView,
            checklistCardView,
            matchCardView,
            recommendationsCardView,
            cvCardView,
            coverLetterCardView,
            emailCardView,
            approvalCardView
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var jobCardView = makeCardView()
    private lazy var routeCardView = makeCardView()
    private lazy var checklistCardView = makeCardView()
    private lazy var matchCardView = makeCardView()
    private lazy var recommendationsCardView = makeCardView()
    private lazy var cvCardView = makeCardView()
    private lazy var coverLetterCardView = makeCardView()
    private lazy var emailCardView = makeCardView()
    private lazy var approvalCardView = makeCardView()

    private lazy var jobTitleLabel = makeSectionTitleLabel(text: "Application Package")
    private lazy var jobSummaryLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .semibold), color: .secondaryLabel, lines: 0)
    private lazy var routeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = AppTheme.brand
        imageView.backgroundColor = AppTheme.mutedSurface
        imageView.contentMode = .center
        imageView.layer.cornerRadius = AppTheme.cardRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private lazy var routeTitleLabel = makeSectionTitleLabel(text: "How You’ll Apply")
    private lazy var routeMethodLabel = makeLabel(font: UIFont.systemFont(ofSize: 17, weight: .bold), color: .label, lines: 0)
    private lazy var routeSummaryLabel = makeLabel(font: UIFont.systemFont(ofSize: 14, weight: .medium), color: AppTheme.secondaryText, lines: 0)
    private lazy var checklistTitleLabel = makeSectionTitleLabel(text: "Required Document Checklist")
    private lazy var checklistStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var scoreLabel: UILabel = {
        let label = makeLabel(font: UIFont.systemFont(ofSize: 42, weight: .bold), color: .systemGreen, lines: 1)
        label.text = "--%"
        label.textAlignment = .center
        return label
    }()

    private lazy var matchTitleLabel = makeSectionTitleLabel(text: "Job Fit")
    private lazy var matchSummaryLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)
    private lazy var recommendationsTitleLabel = makeSectionTitleLabel(text: "Recommendations")
    private lazy var recommendationsLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)
    private lazy var cvTitleLabel = makeSectionTitleLabel(text: "Tailored CV Draft")
    private lazy var coverLetterTitleLabel = makeSectionTitleLabel(text: "Cover Letter")
    private lazy var emailTitleLabel = makeSectionTitleLabel(text: "Recruiter Email Draft")
    private lazy var approvalTitleLabel = makeSectionTitleLabel(text: "Final Approval")
    private lazy var approvalLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)

    private lazy var cvTextView = makeTextView()
    private lazy var coverLetterTextView = makeTextView()
    private lazy var emailTextView = makeTextView()

    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Export CV & Cover Letter",
            systemImageName: "square.and.arrow.up"
        )
        button.configuration?.baseBackgroundColor = AppTheme.mutedSurface
        button.configuration?.baseForegroundColor = AppTheme.brand
        button.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var approveButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Preparing Package",
            systemImageName: "arrow.right"
        )
        button.configuration?.baseBackgroundColor = .systemGray
        button.isEnabled = false
        button.addTarget(self, action: #selector(approveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(job: Job, userProfile: UserProfile) {
        self.job = job
        self.userProfile = userProfile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = "Review Package"
        setupUI()
        configureLoadingState()
        preparePackage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        let debugScroll = ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_AUTO_SCROLL"]
        guard debugScroll == "cover-letter" else { return }

        view.layoutIfNeeded()
        let targetY = max(0, coverLetterCardView.frame.minY - 12)
        scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        #endif
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(approveButton)
        scrollView.addSubview(contentStackView)

        setupJobCard()
        setupRouteCard()
        setupChecklistCard()
        setupMatchCard()
        setupRecommendationsCard()
        setupCVCard()
        setupCoverLetterCard()
        setupEmailCard()
        setupApprovalCard()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: approveButton.topAnchor, constant: -14),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            approveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            approveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            approveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            approveButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func setupJobCard() {
        jobCardView.addSubview(jobTitleLabel)
        jobCardView.addSubview(jobSummaryLabel)

        NSLayoutConstraint.activate([
            jobTitleLabel.topAnchor.constraint(equalTo: jobCardView.topAnchor, constant: 16),
            jobTitleLabel.leadingAnchor.constraint(equalTo: jobCardView.leadingAnchor, constant: 16),
            jobTitleLabel.trailingAnchor.constraint(equalTo: jobCardView.trailingAnchor, constant: -16),

            jobSummaryLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 10),
            jobSummaryLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            jobSummaryLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),
            jobSummaryLabel.bottomAnchor.constraint(equalTo: jobCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupRouteCard() {
        routeCardView.addSubview(routeIconView)
        routeCardView.addSubview(routeTitleLabel)
        routeCardView.addSubview(routeMethodLabel)
        routeCardView.addSubview(routeSummaryLabel)

        NSLayoutConstraint.activate([
            routeIconView.topAnchor.constraint(equalTo: routeCardView.topAnchor, constant: 16),
            routeIconView.leadingAnchor.constraint(equalTo: routeCardView.leadingAnchor, constant: 16),
            routeIconView.widthAnchor.constraint(equalToConstant: 48),
            routeIconView.heightAnchor.constraint(equalToConstant: 48),

            routeTitleLabel.topAnchor.constraint(equalTo: routeIconView.topAnchor),
            routeTitleLabel.leadingAnchor.constraint(equalTo: routeIconView.trailingAnchor, constant: 14),
            routeTitleLabel.trailingAnchor.constraint(equalTo: routeCardView.trailingAnchor, constant: -16),

            routeMethodLabel.topAnchor.constraint(equalTo: routeTitleLabel.bottomAnchor, constant: 5),
            routeMethodLabel.leadingAnchor.constraint(equalTo: routeTitleLabel.leadingAnchor),
            routeMethodLabel.trailingAnchor.constraint(equalTo: routeTitleLabel.trailingAnchor),

            routeSummaryLabel.topAnchor.constraint(equalTo: routeIconView.bottomAnchor, constant: 14),
            routeSummaryLabel.leadingAnchor.constraint(equalTo: routeCardView.leadingAnchor, constant: 16),
            routeSummaryLabel.trailingAnchor.constraint(equalTo: routeCardView.trailingAnchor, constant: -16),
            routeSummaryLabel.bottomAnchor.constraint(equalTo: routeCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupChecklistCard() {
        checklistCardView.addSubview(checklistTitleLabel)
        checklistCardView.addSubview(checklistStackView)

        NSLayoutConstraint.activate([
            checklistTitleLabel.topAnchor.constraint(equalTo: checklistCardView.topAnchor, constant: 16),
            checklistTitleLabel.leadingAnchor.constraint(equalTo: checklistCardView.leadingAnchor, constant: 16),
            checklistTitleLabel.trailingAnchor.constraint(equalTo: checklistCardView.trailingAnchor, constant: -16),

            checklistStackView.topAnchor.constraint(equalTo: checklistTitleLabel.bottomAnchor, constant: 12),
            checklistStackView.leadingAnchor.constraint(equalTo: checklistTitleLabel.leadingAnchor),
            checklistStackView.trailingAnchor.constraint(equalTo: checklistTitleLabel.trailingAnchor),
            checklistStackView.bottomAnchor.constraint(equalTo: checklistCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupMatchCard() {
        matchCardView.addSubview(matchTitleLabel)
        matchCardView.addSubview(scoreLabel)
        matchCardView.addSubview(matchSummaryLabel)

        NSLayoutConstraint.activate([
            matchTitleLabel.topAnchor.constraint(equalTo: matchCardView.topAnchor, constant: 16),
            matchTitleLabel.leadingAnchor.constraint(equalTo: matchCardView.leadingAnchor, constant: 16),
            matchTitleLabel.trailingAnchor.constraint(equalTo: matchCardView.trailingAnchor, constant: -16),

            scoreLabel.topAnchor.constraint(equalTo: matchTitleLabel.bottomAnchor, constant: 14),
            scoreLabel.leadingAnchor.constraint(equalTo: matchTitleLabel.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: matchTitleLabel.trailingAnchor),

            matchSummaryLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            matchSummaryLabel.leadingAnchor.constraint(equalTo: matchTitleLabel.leadingAnchor),
            matchSummaryLabel.trailingAnchor.constraint(equalTo: matchTitleLabel.trailingAnchor),
            matchSummaryLabel.bottomAnchor.constraint(equalTo: matchCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupRecommendationsCard() {
        recommendationsCardView.addSubview(recommendationsTitleLabel)
        recommendationsCardView.addSubview(recommendationsLabel)

        NSLayoutConstraint.activate([
            recommendationsTitleLabel.topAnchor.constraint(equalTo: recommendationsCardView.topAnchor, constant: 16),
            recommendationsTitleLabel.leadingAnchor.constraint(equalTo: recommendationsCardView.leadingAnchor, constant: 16),
            recommendationsTitleLabel.trailingAnchor.constraint(equalTo: recommendationsCardView.trailingAnchor, constant: -16),

            recommendationsLabel.topAnchor.constraint(equalTo: recommendationsTitleLabel.bottomAnchor, constant: 10),
            recommendationsLabel.leadingAnchor.constraint(equalTo: recommendationsTitleLabel.leadingAnchor),
            recommendationsLabel.trailingAnchor.constraint(equalTo: recommendationsTitleLabel.trailingAnchor),
            recommendationsLabel.bottomAnchor.constraint(equalTo: recommendationsCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupCVCard() {
        cvCardView.addSubview(cvTitleLabel)
        cvCardView.addSubview(cvTextView)

        NSLayoutConstraint.activate([
            cvTitleLabel.topAnchor.constraint(equalTo: cvCardView.topAnchor, constant: 16),
            cvTitleLabel.leadingAnchor.constraint(equalTo: cvCardView.leadingAnchor, constant: 16),
            cvTitleLabel.trailingAnchor.constraint(equalTo: cvCardView.trailingAnchor, constant: -16),

            cvTextView.topAnchor.constraint(equalTo: cvTitleLabel.bottomAnchor, constant: 10),
            cvTextView.leadingAnchor.constraint(equalTo: cvTitleLabel.leadingAnchor),
            cvTextView.trailingAnchor.constraint(equalTo: cvTitleLabel.trailingAnchor),
            cvTextView.heightAnchor.constraint(equalToConstant: 240),
            cvTextView.bottomAnchor.constraint(equalTo: cvCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupCoverLetterCard() {
        coverLetterCardView.addSubview(coverLetterTitleLabel)
        coverLetterCardView.addSubview(coverLetterTextView)

        NSLayoutConstraint.activate([
            coverLetterTitleLabel.topAnchor.constraint(equalTo: coverLetterCardView.topAnchor, constant: 16),
            coverLetterTitleLabel.leadingAnchor.constraint(equalTo: coverLetterCardView.leadingAnchor, constant: 16),
            coverLetterTitleLabel.trailingAnchor.constraint(equalTo: coverLetterCardView.trailingAnchor, constant: -16),

            coverLetterTextView.topAnchor.constraint(equalTo: coverLetterTitleLabel.bottomAnchor, constant: 10),
            coverLetterTextView.leadingAnchor.constraint(equalTo: coverLetterTitleLabel.leadingAnchor),
            coverLetterTextView.trailingAnchor.constraint(equalTo: coverLetterTitleLabel.trailingAnchor),
            coverLetterTextView.heightAnchor.constraint(equalToConstant: 260),
            coverLetterTextView.bottomAnchor.constraint(equalTo: coverLetterCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupEmailCard() {
        emailCardView.addSubview(emailTitleLabel)
        emailCardView.addSubview(emailTextView)

        NSLayoutConstraint.activate([
            emailTitleLabel.topAnchor.constraint(equalTo: emailCardView.topAnchor, constant: 16),
            emailTitleLabel.leadingAnchor.constraint(equalTo: emailCardView.leadingAnchor, constant: 16),
            emailTitleLabel.trailingAnchor.constraint(equalTo: emailCardView.trailingAnchor, constant: -16),

            emailTextView.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 10),
            emailTextView.leadingAnchor.constraint(equalTo: emailTitleLabel.leadingAnchor),
            emailTextView.trailingAnchor.constraint(equalTo: emailTitleLabel.trailingAnchor),
            emailTextView.heightAnchor.constraint(equalToConstant: 220),
            emailTextView.bottomAnchor.constraint(equalTo: emailCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupApprovalCard() {
        approvalCardView.addSubview(approvalTitleLabel)
        approvalCardView.addSubview(approvalLabel)
        approvalCardView.addSubview(exportButton)

        NSLayoutConstraint.activate([
            approvalTitleLabel.topAnchor.constraint(equalTo: approvalCardView.topAnchor, constant: 16),
            approvalTitleLabel.leadingAnchor.constraint(equalTo: approvalCardView.leadingAnchor, constant: 16),
            approvalTitleLabel.trailingAnchor.constraint(equalTo: approvalCardView.trailingAnchor, constant: -16),

            approvalLabel.topAnchor.constraint(equalTo: approvalTitleLabel.bottomAnchor, constant: 10),
            approvalLabel.leadingAnchor.constraint(equalTo: approvalTitleLabel.leadingAnchor),
            approvalLabel.trailingAnchor.constraint(equalTo: approvalTitleLabel.trailingAnchor),

            exportButton.topAnchor.constraint(equalTo: approvalLabel.bottomAnchor, constant: 14),
            exportButton.leadingAnchor.constraint(equalTo: approvalTitleLabel.leadingAnchor),
            exportButton.trailingAnchor.constraint(equalTo: approvalTitleLabel.trailingAnchor),
            exportButton.heightAnchor.constraint(equalToConstant: 50),
            exportButton.bottomAnchor.constraint(equalTo: approvalCardView.bottomAnchor, constant: -16)
        ])
    }

    private func configureLoadingState() {
        jobSummaryLabel.text = "\(job.title)\n\(job.companyName)\n\(job.locationText)\n\(job.salaryText)"
        routeIconView.image = UIImage(systemName: job.applicationRoute.systemImageName)
        routeMethodLabel.text = job.applicationRoute.title
        routeSummaryLabel.text = applicationRouteSummary()
        configureChecklist()
        matchSummaryLabel.text = "Preparing your job fit score, tailored CV, cover letter, and email draft."
        recommendationsLabel.text = "Loading recommendations..."
        cvTextView.text = "Preparing tailored CV draft..."
        coverLetterTextView.text = "Preparing cover letter..."
        emailTextView.text = "Preparing email draft..."
        approvalLabel.text = approvalText()
    }

    private func configureChecklist() {
        checklistStackView.arrangedSubviews.forEach {
            checklistStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let checklistItems = requiredChecklistItems()
        checklistCardView.isHidden = checklistItems.isEmpty

        checklistItems.forEach { item in
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = item
            configuration.image = UIImage(systemName: "circle")
            configuration.imagePadding = 10
            configuration.imagePlacement = .leading
            configuration.baseForegroundColor = .label
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: 9,
                leading: 0,
                bottom: 9,
                trailing: 0
            )
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var updatedAttributes = attributes
                updatedAttributes.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                return updatedAttributes
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.addTarget(self, action: #selector(checklistItemTapped(_:)), for: .touchUpInside)
            checklistStackView.addArrangedSubview(button)
        }
    }

    private func requiredChecklistItems() -> [String] {
        var items = job.application.requiredForms + job.application.requiredDocuments

        if job.application.requiresZ83
            || job.application.formName.lowercased().contains("z83")
            || job.description.lowercased().contains("z83") {
            items.removeAll { $0.lowercased().contains("z83") }
            items.append("Completed and signed Z83 form")
            items.append("Vacancy reference number checked")
        }

        if job.application.requiresCV || items.isEmpty {
            items.append("Tailored CV")
        }

        if job.application.requiresCoverLetter {
            items.append("Tailored cover letter")
        }

        if job.application.requiresCertifiedDocuments {
            items.append("Certified supporting documents")
        }

        guard job.applicationRoute == .requiredForm
                || job.applicationRoute == .manual
                || !job.application.requiredDocuments.isEmpty else {
            return []
        }

        var seen = Set<String>()
        return items.filter {
            let key = $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func preparePackage() {
        aiCareerService.prepareAutoApplyPackage(userProfile: userProfile, job: job) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let package):
                    self?.autoApplyPackage = package
                    self?.configure(with: package)
                case .failure(let error):
                    self?.showAlert(title: "Assistant Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func configure(with package: AutoApplyPackage) {
        scoreLabel.text = "\(package.matchScore)%"
        matchSummaryLabel.text = package.matchSummary
        recommendationsLabel.text = bulletText(package.recommendations)
        cvTextView.text = package.tailoredCVText
        coverLetterTextView.text = package.coverLetterText
        emailTextView.text = "Subject: \(package.emailSubject)\n\n\(package.emailBody)"
        approveButton.isEnabled = true
        approveButton.configuration?.title = job.applicationRoute.actionTitle
        approveButton.configuration?.baseBackgroundColor = AppTheme.brand

        #if DEBUG
        if ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_GENERATE_DOCUMENTS"] == "1" {
            do {
                try generatedDocumentURLs().forEach {
                    print("LET_APPLY_DEBUG_DOCUMENT=\($0.path)")
                }
            } catch {
                print("LET_APPLY_DEBUG_DOCUMENT_ERROR=\(error.localizedDescription)")
            }
        }
        #endif
    }

    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func makeSectionTitleLabel(text: String) -> UILabel {
        let label = makeLabel(font: UIFont.systemFont(ofSize: 18, weight: .bold), color: .label, lines: 1)
        label.text = text
        return label
    }

    private func makeLabel(font: UIFont, color: UIColor, lines: Int) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeTextView() -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.background
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }

    private func bulletText(_ items: [String]) -> String {
        guard !items.isEmpty else {
            return "No recommendations yet."
        }

        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private func applicationRouteSummary() -> String {
        switch job.applicationRoute {
        case .inApp:
            return "Your reviewed package will be submitted securely and added to your application tracker."
        case .email:
            return "Let’s Apply will open a pre-addressed email, attach your local CV and cover-letter PDFs, and wait for you to tap Send."
        case .externalPortal:
            return "Your package will be saved locally, then the employer’s official portal will open so you can complete its required questions."
        case .requiredForm:
            let formName = job.application.formName.isEmpty ? "the required employment form" : job.application.formName
            let requiredItems = job.application.requiredForms + job.application.requiredDocuments
            let documents = requiredItems.isEmpty
                ? "your CV and cover letter"
                : requiredItems.joined(separator: ", ")
            return "This vacancy requires \(formName). Let’s Apply prepares \(documents), but declarations and signatures remain under your control."
        case .manual:
            return job.application.applicationInstructions.isEmpty
                ? "This employer provided manual application instructions. Let’s Apply will prepare the documents and keep the final action under your control."
                : job.application.applicationInstructions
        }
    }

    private func approvalText() -> String {
        switch job.applicationRoute {
        case .inApp:
            return "Review every section before submitting. Let’s Apply will never send an application without your approval."
        case .email:
            return "Review the CV, cover letter, and email. Your device’s Mail composer opens next; nothing is sent until you tap Send."
        case .externalPortal:
            return "Export your documents at any time. Approval saves this package as ready and opens the employer’s official application portal."
        case .requiredForm:
            return "Export the prepared documents, open the required form, and check every declaration before signing or submitting."
        case .manual:
            return "Review the employer’s instructions carefully. You can export the CV and cover letter before completing the requested manual steps."
        }
    }

    private func emailDraftParts() -> (subject: String?, body: String?) {
        let text = emailTextView.text ?? ""
        let prefix = "Subject:"

        guard text.hasPrefix(prefix), let bodyRange = text.range(of: "\n\n") else {
            return (nil, text)
        }

        let subjectStart = text.index(text.startIndex, offsetBy: prefix.count)
        let subject = String(text[subjectStart..<bodyRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let body = String(text[bodyRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (subject, body)
    }

    @objc private func approveTapped() {
        guard !isSubmitting else { return }
        guard autoApplyPackage != nil else {
            showAlert(title: "Package Not Ready", message: "Please wait for the assistant to finish preparing your package.")
            return
        }

        guard let user = Auth.auth().currentUser, !user.isAnonymous, user.uid == userProfile.uid else {
            showAlert(title: "Create Profile", message: "Please sign in before submitting this application.")
            return
        }

        let confirmation = confirmationContent()
        let alert = UIAlertController(
            title: confirmation.title,
            message: confirmation.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: confirmation.actionTitle, style: .default) { [weak self] _ in
            self?.continueApprovedPackage()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func exportTapped() {
        presentDocumentExport(openDestinationAfter: false)
    }

    @objc private func checklistItemTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.configuration?.image = UIImage(
            systemName: sender.isSelected ? "checkmark.circle.fill" : "circle"
        )
        sender.configuration?.baseForegroundColor = sender.isSelected ? AppTheme.brand : .label
    }

    private func confirmationContent() -> (title: String, message: String, actionTitle: String) {
        switch job.applicationRoute {
        case .inApp:
            return (
                "Submit Application?",
                "Your reviewed package will be submitted and recorded in your tracker.",
                "Submit"
            )
        case .email:
            return (
                "Open Email Application?",
                "Let’s Apply will prepare the recipient, subject, message, CV, and cover letter. You will review everything again before tapping Send.",
                "Open Email"
            )
        case .externalPortal:
            return (
                "Continue to Employer Portal?",
                "Your package will be saved as ready to submit. The employer’s website will open for any final questions and declarations.",
                "Continue"
            )
        case .requiredForm:
            return (
                "Prepare Required Form?",
                "Your CV and cover letter will be available to export before the official application form opens. You remain in control of declarations and signatures.",
                "Prepare"
            )
        case .manual:
            return (
                "Prepare Manual Application?",
                "Let’s Apply will save the package as ready and show the employer’s instructions. Nothing will be submitted automatically.",
                "Prepare"
            )
        }
    }

    private func continueApprovedPackage() {
        switch job.applicationRoute {
        case .inApp:
            saveApplication(status: "submitted") { [weak self] in
                self?.onApplicationSubmitted?()
                self?.showSuccessAlert()
            }
        case .email:
            openEmailApplication()
        case .externalPortal, .requiredForm:
            saveApplication(status: "ready-to-submit") { [weak self] in
                self?.presentDocumentExport(openDestinationAfter: true)
            }
        case .manual:
            saveApplication(status: "requires-manual-action") { [weak self] in
                self?.showManualInstructions()
            }
        }
    }

    private func saveApplication(
        status: String,
        completion: @escaping () -> Void
    ) {
        setSubmitting(true)
        let emailDraft = emailDraftParts()

        firestoreService.createApplication(
            userProfile: userProfile,
            job: job,
            coverLetterText: coverLetterTextView.text,
            isAIGenerated: true,
            tailoredCVText: cvTextView.text,
            recruiterEmailSubject: emailDraft.subject,
            recruiterEmailBody: emailDraft.body,
            matchScore: autoApplyPackage?.matchScore,
            status: status,
            applicationMethod: job.applicationRoute.trackerValue,
            applicationDestination: applicationDestination()
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setSubmitting(false)

                switch result {
                case .success:
                    completion()
                case .failure(let error):
                    self.showAlert(title: "Application Not Submitted", message: error.localizedDescription)
                }
            }
        }
    }

    private func openEmailApplication() {
        guard MFMailComposeViewController.canSendMail() else {
            showEmailFallbackAlert()
            return
        }

        do {
            let urls = try generatedDocumentURLs()
            let emailDraft = emailDraftParts()
            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients([job.application.applicationEmail])
            composer.setSubject(emailDraft.subject ?? "Application for \(job.title)")
            composer.setMessageBody(emailDraft.body ?? "", isHTML: false)

            for url in urls {
                let data = try Data(contentsOf: url)
                composer.addAttachmentData(
                    data,
                    mimeType: "application/pdf",
                    fileName: url.lastPathComponent
                )
            }

            present(composer, animated: true)
        } catch {
            showAlert(title: "Documents Not Ready", message: error.localizedDescription)
        }
    }

    private func showEmailFallbackAlert() {
        let alert = UIAlertController(
            title: "Mail Is Not Set Up",
            message: "Export the CV and cover letter, then attach them in your preferred email app. The recruiter email and draft remain available on this screen.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Export Documents", style: .default) { [weak self] _ in
            self?.presentDocumentExport(openDestinationAfter: false)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showManualInstructions() {
        let instructions = job.application.applicationInstructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let alert = UIAlertController(
            title: "Application Instructions",
            message: instructions.isEmpty
                ? "Export your application documents and follow the instructions in the vacancy advert."
                : instructions,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Export Documents", style: .default) { [weak self] _ in
            self?.presentDocumentExport(openDestinationAfter: false)
        })
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }

    private func generatedDocumentURLs() throws -> [URL] {
        var tailoredProfile = userProfile
        tailoredProfile.jobTitle = job.title

        let cvURL = try pdfService.generateCV(for: tailoredProfile)
        let coverLetterURL = try pdfService.generateCoverLetter(
            for: tailoredProfile,
            job: job,
            text: coverLetterTextView.text ?? ""
        )
        return [cvURL, coverLetterURL]
    }

    private func presentDocumentExport(openDestinationAfter: Bool) {
        do {
            let urls = try generatedDocumentURLs()
            let activityController = UIActivityViewController(
                activityItems: urls,
                applicationActivities: nil
            )
            activityController.popoverPresentationController?.sourceView = exportButton
            activityController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
                guard openDestinationAfter, completed else { return }
                self?.openApplicationDestination()
            }
            present(activityController, animated: true)
        } catch {
            showAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }

    private func openApplicationDestination() {
        guard let url = applicationDestinationURL() else {
            showAlert(
                title: "Application Destination Missing",
                message: "This vacancy does not include a valid form or employer portal URL. Your documents are ready to share manually."
            )
            return
        }

        present(SFSafariViewController(url: url), animated: true)
    }

    private func applicationDestinationURL() -> URL? {
        let rawURL = job.application.applicationUrl
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !rawURL.isEmpty {
            return URL(string: rawURL)
        }

        let formText = """
        \(job.application.formName)
        \(job.application.requiredForms.joined(separator: " "))
        \(job.application.requiredDocuments.joined(separator: " "))
        """
            .lowercased()
        if job.application.requiresZ83 || formText.contains("z83") {
            return URL(string: "https://www.dpsa.gov.za/dpsa2g/documents/vacancies/editable%20Approved%20New%20Z83%20form%20Gazetted%206%20Nov%202020.pdf")
        }

        return nil
    }

    private func applicationDestination() -> String? {
        switch job.applicationRoute {
        case .email:
            return job.application.applicationEmail
        case .externalPortal, .requiredForm:
            return applicationDestinationURL()?.absoluteString
        case .inApp:
            return "Let’s Apply"
        case .manual:
            return job.application.applicationInstructions
        }
    }

    private func setSubmitting(_ submitting: Bool) {
        isSubmitting = submitting
        approveButton.isEnabled = !submitting
        exportButton.isEnabled = !submitting
        approveButton.configuration?.baseBackgroundColor = submitting ? .systemGray : AppTheme.brand
        approveButton.configuration?.title = submitting ? "Saving..." : job.applicationRoute.actionTitle
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Application Submitted",
            message: "Your reviewed application package has been added to your tracker.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "View Applications", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let applicationsVC = ApplicationsViewController(userId: self.userProfile.uid)
            applicationsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(applicationsVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AutoApplyAssistantViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Email Not Sent", message: error.localizedDescription)
                return
            }

            switch result {
            case .sent:
                self.saveApplication(status: "submitted") {
                    self.onApplicationSubmitted?()
                    self.showSuccessAlert()
                }
            case .saved:
                self.saveApplication(status: "email-draft") {
                    self.showAlert(
                        title: "Email Draft Saved",
                        message: "Your application package is saved in Mail and in your Let’s Apply tracker."
                    )
                }
            case .failed:
                self.showAlert(
                    title: "Email Not Sent",
                    message: "Mail could not send this application. Export the documents and try your preferred email app."
                )
            case .cancelled:
                break
            @unknown default:
                break
            }
        }
    }
}
