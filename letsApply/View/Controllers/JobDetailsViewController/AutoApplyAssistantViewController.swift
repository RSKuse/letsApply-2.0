//
//  AutoApplyAssistantViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth

class AutoApplyAssistantViewController: UIViewController {

    var onApplicationSubmitted: (() -> Void)?

    private let job: Job
    private let userProfile: UserProfile
    private let aiCareerService = AICareerService()
    private let firestoreService = FirestoreService()
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
    private lazy var matchCardView = makeCardView()
    private lazy var recommendationsCardView = makeCardView()
    private lazy var cvCardView = makeCardView()
    private lazy var coverLetterCardView = makeCardView()
    private lazy var emailCardView = makeCardView()
    private lazy var approvalCardView = makeCardView()

    private lazy var jobTitleLabel = makeSectionTitleLabel(text: "Application Package")
    private lazy var jobSummaryLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .semibold), color: .secondaryLabel, lines: 0)

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

    private lazy var approveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Approve & Submit Application", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 14
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
        view.backgroundColor = .systemBackground
        title = "Review Package"
        setupUI()
        configureLoadingState()
        preparePackage()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(approveButton)
        scrollView.addSubview(contentStackView)

        setupJobCard()
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

        NSLayoutConstraint.activate([
            approvalTitleLabel.topAnchor.constraint(equalTo: approvalCardView.topAnchor, constant: 16),
            approvalTitleLabel.leadingAnchor.constraint(equalTo: approvalCardView.leadingAnchor, constant: 16),
            approvalTitleLabel.trailingAnchor.constraint(equalTo: approvalCardView.trailingAnchor, constant: -16),

            approvalLabel.topAnchor.constraint(equalTo: approvalTitleLabel.bottomAnchor, constant: 10),
            approvalLabel.leadingAnchor.constraint(equalTo: approvalTitleLabel.leadingAnchor),
            approvalLabel.trailingAnchor.constraint(equalTo: approvalTitleLabel.trailingAnchor),
            approvalLabel.bottomAnchor.constraint(equalTo: approvalCardView.bottomAnchor, constant: -16)
        ])
    }

    private func configureLoadingState() {
        jobSummaryLabel.text = "\(job.title)\n\(job.companyName)\n\(job.locationText)"
        matchSummaryLabel.text = "Preparing your job fit score, tailored CV, cover letter, and email draft."
        recommendationsLabel.text = "Loading recommendations..."
        cvTextView.text = "Preparing tailored CV draft..."
        coverLetterTextView.text = "Preparing cover letter..."
        emailTextView.text = "Preparing email draft..."
        approvalLabel.text = approvalText()
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
        approveButton.backgroundColor = .systemGreen
    }

    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.borderColor = UIColor.systemGray5.cgColor
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
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderColor = UIColor.systemGray5.cgColor
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

    private func approvalText() -> String {
        if AppFeatures.firebaseStorageUploadsEnabled {
            return "Review every section. When you approve, Let’s Apply stores the submitted package in your application tracker."
        }

        return "Review every section. PDF upload is paused on the free plan, so this application will use your profile CV draft, cover letter, and recruiter email text."
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

        let alert = UIAlertController(
            title: "Approve Application",
            message: "This will submit the reviewed package to your application tracker. Let’s Apply will not send anything until you approve.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            self?.submitApprovedPackage()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func submitApprovedPackage() {
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
            matchScore: autoApplyPackage?.matchScore
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setSubmitting(false)

                switch result {
                case .success:
                    self.onApplicationSubmitted?()
                    self.showSuccessAlert()
                case .failure(let error):
                    self.showAlert(title: "Application Not Submitted", message: error.localizedDescription)
                }
            }
        }
    }

    private func setSubmitting(_ submitting: Bool) {
        isSubmitting = submitting
        approveButton.isEnabled = !submitting
        approveButton.backgroundColor = submitting ? .systemGray : .systemGreen
        approveButton.setTitle(submitting ? "Submitting..." : "Approve & Submit Application", for: .normal)
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
