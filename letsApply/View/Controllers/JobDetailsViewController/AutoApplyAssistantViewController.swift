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
    private let z83PDFService = Z83PDFService()
    private let z83ProfileStore = Z83ProfileStore()
    private var autoApplyPackage: AutoApplyPackage?
    private var preparedZ83URL: URL?
    private var isSubmitting = false
    private var didRunDebugAutomation = false

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

    private lazy var jobTitleLabel = makeSectionTitleLabel(text: "Application Details")
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

    private lazy var prepareZ83Button: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Complete and Sign Z83",
            systemImageName: "signature"
        )
        button.configuration?.baseBackgroundColor = AppTheme.mutedSurface
        button.configuration?.baseForegroundColor = AppTheme.brand
        button.addTarget(self, action: #selector(prepareZ83Tapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
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
    private lazy var cvTitleLabel = makeSectionTitleLabel(text: "CV Attachment Preview")
    private lazy var coverLetterTitleLabel = makeSectionTitleLabel(text: "Editable Cover Letter")
    private lazy var emailTitleLabel = makeSectionTitleLabel(text: "Editable Application Email")
    private lazy var approvalTitleLabel = makeSectionTitleLabel(text: "Before You Continue")
    private lazy var approvalLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)

    private lazy var cvTextView = makeTextView(isEditable: false)
    private lazy var coverLetterTextView = makeTextView()
    private lazy var emailTextView = makeTextView()

    private lazy var copyCoverLetterButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Copy Cover Letter"
        configuration.image = UIImage(systemName: "doc.on.doc")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 12,
            bottom: 10,
            trailing: 12
        )
        button.configuration = configuration
        button.addTarget(self, action: #selector(copyCoverLetterTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Share Application Documents",
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
            title: "Preparing Application",
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
        title = "Review Application"
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
        coverLetterCardView.addSubview(copyCoverLetterButton)

        NSLayoutConstraint.activate([
            coverLetterTitleLabel.topAnchor.constraint(equalTo: coverLetterCardView.topAnchor, constant: 16),
            coverLetterTitleLabel.leadingAnchor.constraint(equalTo: coverLetterCardView.leadingAnchor, constant: 16),
            coverLetterTitleLabel.trailingAnchor.constraint(equalTo: coverLetterCardView.trailingAnchor, constant: -16),

            coverLetterTextView.topAnchor.constraint(equalTo: coverLetterTitleLabel.bottomAnchor, constant: 10),
            coverLetterTextView.leadingAnchor.constraint(equalTo: coverLetterTitleLabel.leadingAnchor),
            coverLetterTextView.trailingAnchor.constraint(equalTo: coverLetterTitleLabel.trailingAnchor),
            coverLetterTextView.heightAnchor.constraint(equalToConstant: 260),

            copyCoverLetterButton.topAnchor.constraint(equalTo: coverLetterTextView.bottomAnchor, constant: 8),
            copyCoverLetterButton.trailingAnchor.constraint(equalTo: coverLetterTitleLabel.trailingAnchor),
            copyCoverLetterButton.bottomAnchor.constraint(equalTo: coverLetterCardView.bottomAnchor, constant: -10)
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
        routeMethodLabel.text = job.applicationMethod.reviewTitle
        routeSummaryLabel.text = applicationRouteSummary()
        emailCardView.isHidden = job.applicationRoute != .email
        configureChecklist()
        matchSummaryLabel.text = "Checking the vacancy against evidence in your profile."
        recommendationsLabel.text = "Loading recommendations..."
        cvTextView.text = "Preparing CV preview..."
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

        if job.requiresGovernmentFlow {
            refreshPreparedZ83()
            checklistStackView.addArrangedSubview(prepareZ83Button)
        }

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
            if item.lowercased().contains("z83") {
                button.isSelected = preparedZ83URL != nil
                button.configuration?.image = UIImage(
                    systemName: button.isSelected ? "checkmark.circle.fill" : "circle"
                )
                button.configuration?.baseForegroundColor = button.isSelected
                    ? AppTheme.brand
                    : .label
                button.isUserInteractionEnabled = false
            }
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
            let reference = job.application.referenceNumber
                .trimmingCharacters(in: .whitespacesAndNewlines)
            items.append(
                reference.isEmpty
                    ? "Vacancy reference number checked"
                    : "Reference \(reference) confirmed"
            )
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

        if job.application.requiresDriversLicense {
            items.append("Driver’s licence copy")
        }

        guard job.requiresGovernmentFlow
                || job.applicationRoute == .requiredForm
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

        if !didRunDebugAutomation,
           ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_EMAIL_PREVIEW"] == "1" {
            didRunDebugAutomation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openEmailPreview()
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

    private func makeTextView(isEditable: Bool = true) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.background
        textView.isEditable = isEditable
        textView.isSelectable = true
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
        if job.requiresGovernmentFlow {
            switch job.applicationMethod {
            case .governmentEmail:
                return "Review the government checklist first. Submit Application then opens a prepared email with your CV and cover letter attached for your approval."
            case .governmentWebsite:
                return "Complete the government checklist, prepare your Z83, CV, and cover letter, then continue to \(job.applicationWebsiteName) to finish the official submission."
            case .governmentManual, .pdfCircular:
                return job.application.applicationInstructions.isEmpty
                    ? "Review the circular, Z83 requirements, supporting documents, reference number, and delivery instructions before continuing."
                    : job.application.applicationInstructions
            default:
                break
            }
        }

        switch job.applicationRoute {
        case .inApp:
            return "Your application will be submitted in Let’s Apply and added to your application tracker."
        case .email:
            return "A ready-to-send email will open with the employer’s address, your message, CV, and cover letter. You review it and tap Send."
        case .externalPortal:
            return "Your documents will be prepared first. You can save or share them, copy the official link, and then continue to \(job.applicationWebsiteName)."
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
            return "Mail opens next with your documents attached. The application is tracked only after Mail confirms that you sent it."
        case .externalPortal:
            return "Save or share the prepared documents before opening the official website. The application remains marked Continue until you finish it there."
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
            showAlert(title: "Application Not Ready", message: "Please wait while Let’s Apply finishes preparing your documents.")
            return
        }

        #if DEBUG
        let debugAccess = ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_AUTH"] == "1"
        #else
        let debugAccess = false
        #endif

        guard debugAccess
                || (Auth.auth().currentUser.map {
                    !$0.isAnonymous && $0.uid == userProfile.uid
                } ?? false) else {
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

    @objc private func copyCoverLetterTapped() {
        UIPasteboard.general.string = coverLetterTextView.text
        showAlert(
            title: "Cover Letter Copied",
            message: "The cover letter is ready to paste into an employer form or application website."
        )
    }

    @objc private func checklistItemTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.configuration?.image = UIImage(
            systemName: sender.isSelected ? "checkmark.circle.fill" : "circle"
        )
        sender.configuration?.baseForegroundColor = sender.isSelected ? AppTheme.brand : .label
    }

    @objc private func prepareZ83Tapped() {
        let editor = Z83EditorViewController(job: job, userProfile: userProfile)
        editor.onZ83Ready = { [weak self] url in
            self?.preparedZ83URL = url
            self?.configureChecklist()
            self?.showAlert(
                title: "Z83 Ready",
                message: "The signed Z83 will be included with this application. You can reopen it to review or edit it before submitting."
            )
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    private func confirmationContent() -> (title: String, message: String, actionTitle: String) {
        switch job.applicationRoute {
        case .inApp:
            return (
                "Submit Application?",
                "Your reviewed application will be submitted in Let’s Apply and recorded in your tracker.",
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
                "Prepare Website Application?",
                "Let’s Apply will keep your Z83, CV, and cover letter ready, then give you options to save the documents or open the official application website.",
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
                "View Employer Instructions?",
                "Let’s Apply will save this application as a draft and show the employer’s instructions. Nothing will be submitted automatically.",
                "View Instructions"
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
                self?.showPortalHandoffOptions()
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
            applicationMethod: job.applicationMethod.rawValue,
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
        let title: String
        let message: String
        #if targetEnvironment(simulator)
        title = "Simulator Email Preview"
        message = "Apple Mail cannot send from iOS Simulator. Preview the complete prepared email and all attachments here, then test the final Send action on a physical iPhone."
        #else
        title = "Mail Is Not Set Up"
        message = "Configure an account in Apple Mail, or preview and share the generated application documents with your preferred email app."
        #endif

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Preview Prepared Email", style: .default) { [weak self] _ in
            self?.openEmailPreview()
        })
        alert.addAction(UIAlertAction(title: "Share Documents", style: .default) { [weak self] _ in
            self?.presentDocumentExport(openDestinationAfter: false)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func openEmailPreview() {
        do {
            let urls = try generatedDocumentURLs()
            let draft = emailDraftParts()
            let preview = EmailApplicationPreviewViewController(
                recipient: job.application.applicationEmail,
                subject: draft.subject ?? "Application for \(job.title)",
                body: draft.body ?? "",
                attachmentURLs: urls
            )
            navigationController?.pushViewController(preview, animated: true)
        } catch {
            showAlert(title: "Documents Not Ready", message: error.localizedDescription)
        }
    }

    private func showManualInstructions() {
        let instructions = manualInstructionsText()
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

    private func showPortalHandoffOptions() {
        guard applicationDestinationURL() != nil else {
            showAlert(
                title: "Application Website Missing",
                message: "The vacancy does not include a verified application website. Your documents remain ready to share manually."
            )
            return
        }

        let alert = UIAlertController(
            title: "Application Package Ready",
            message: "Save or share your documents before completing the official questions and declarations on \(job.applicationWebsiteName).",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Save or Share Documents", style: .default) { [weak self] _ in
            self?.presentDocumentExport(openDestinationAfter: false)
        })
        alert.addAction(UIAlertAction(title: "Open Official Website", style: .default) { [weak self] _ in
            self?.openApplicationDestination()
        })
        alert.addAction(UIAlertAction(title: "Copy Website Link", style: .default) { [weak self] _ in
            guard let self, let url = self.applicationDestinationURL() else { return }
            UIPasteboard.general.string = url.absoluteString
            self.showAlert(
                title: "Website Copied",
                message: "The official application link is ready to paste into Safari."
            )
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = approveButton
        present(alert, animated: true)
    }

    private func manualInstructionsText() -> String {
        let values = [
            job.application.applicationInstructions,
            job.application.referenceNumber.isEmpty
                ? ""
                : "Reference: \(job.application.referenceNumber)",
            job.application.postalAddress.isEmpty
                ? ""
                : "Postal address: \(job.application.postalAddress)",
            job.application.handDeliveryAddress.isEmpty
                ? ""
                : "Hand delivery: \(job.application.handDeliveryAddress)"
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        return values.joined(separator: "\n\n")
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
        var urls = [cvURL, coverLetterURL]
        if job.requiresGovernmentFlow {
            guard let z83URL = resolvedZ83URL() else {
                throw Z83PDFService.Z83PDFError.incomplete([
                    "open Complete and Sign Z83, review the declarations, and add your signature"
                ])
            }
            urls.insert(z83URL, at: 0)
        }
        return urls
    }

    private func refreshPreparedZ83() {
        guard job.requiresGovernmentFlow,
              let profile = z83ProfileStore.load(userId: userProfile.uid),
              profile.isComplete else {
            preparedZ83URL = nil
            prepareZ83Button.configuration?.title = "Complete and Sign Z83"
            prepareZ83Button.configuration?.image = UIImage(systemName: "signature")
            return
        }

        preparedZ83URL = try? z83PDFService.generateZ83(
            profile: profile,
            userProfile: userProfile,
            job: job
        )
        prepareZ83Button.configuration?.title = "Review or Edit Z83"
        prepareZ83Button.configuration?.image = UIImage(systemName: "checkmark.seal.fill")
    }

    private func resolvedZ83URL() -> URL? {
        if let preparedZ83URL, FileManager.default.fileExists(atPath: preparedZ83URL.path) {
            return preparedZ83URL
        }
        refreshPreparedZ83()
        return preparedZ83URL
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
                message: "This vacancy does not include a valid form or employer website. Your documents are ready to share manually."
            )
            return
        }

        present(SFSafariViewController(url: url), animated: true)
    }

    private func applicationDestinationURL() -> URL? {
        let rawURL = job.resolvedApplicationURLString
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
        approveButton.configuration?.title = submitting
            ? job.applicationRoute.progressTitle
            : job.applicationRoute.actionTitle
    }

    private func showSuccessAlert() {
        let message: String
        switch job.applicationRoute {
        case .email:
            message = "Mail confirmed that your application email was sent. It is now recorded in your tracker."
        case .inApp:
            message = "Your application was submitted in Let’s Apply and added to your tracker."
        default:
            message = "Your application has been updated in your tracker."
        }

        let alert = UIAlertController(
            title: "Application Submitted",
            message: message,
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
                self.saveApplication(status: "applied-by-email") {
                    self.onApplicationSubmitted?()
                    self.showSuccessAlert()
                }
            case .saved:
                self.saveApplication(status: "email-draft") {
                    self.showAlert(
                        title: "Email Draft Saved",
                        message: "Your email draft is saved in Mail and listed in your Let’s Apply tracker."
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
