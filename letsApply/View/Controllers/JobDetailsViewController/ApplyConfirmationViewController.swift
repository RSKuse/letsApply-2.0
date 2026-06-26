//
//  ApplyConfirmationViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth
import UniformTypeIdentifiers

class ApplyConfirmationViewController: UIViewController {

    var onApplicationSubmitted: (() -> Void)?

    private let job: Job
    private let firestoreService = FirestoreService()
    private var userProfile: UserProfile
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
            profileCardView,
            cvCardView,
            applicationCardView
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var jobCardView = makeCardView()
    private lazy var profileCardView = makeCardView()
    private lazy var cvCardView = makeCardView()
    private lazy var applicationCardView = makeCardView()

    private lazy var jobIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "briefcase.fill"))
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var jobTitleLabel = makeLabel(font: UIFont.systemFont(ofSize: 23, weight: .bold), color: .label, lines: 0)
    private lazy var companyLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .semibold), color: .secondaryLabel, lines: 0)
    private lazy var profileTitleLabel = makeSectionTitleLabel(text: "Profile")
    private lazy var profileDetailsLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)
    private lazy var cvTitleLabel = makeSectionTitleLabel(text: "CV")
    private lazy var cvStatusLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .bold), color: .secondaryLabel, lines: 0)
    private lazy var applicationTitleLabel = makeSectionTitleLabel(text: "Application")
    private lazy var applicationDetailsLabel = makeLabel(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .secondaryLabel, lines: 0)

    private lazy var uploadCVButton: UIButton = {
        let button = makeSecondaryButton(title: "Upload CV PDF")
        button.addTarget(self, action: #selector(uploadCVTapped), for: .touchUpInside)
        return button
    }()

    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit Application", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
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
        title = "Apply"
        setupUI()
        configure()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(submitButton)
        scrollView.addSubview(contentStackView)

        setupJobCard()
        setupProfileCard()
        setupCVCard()
        setupApplicationCard()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -14),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            submitButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func setupJobCard() {
        jobCardView.addSubview(jobIconView)
        jobCardView.addSubview(jobTitleLabel)
        jobCardView.addSubview(companyLabel)

        NSLayoutConstraint.activate([
            jobIconView.topAnchor.constraint(equalTo: jobCardView.topAnchor, constant: 18),
            jobIconView.leadingAnchor.constraint(equalTo: jobCardView.leadingAnchor, constant: 18),
            jobIconView.widthAnchor.constraint(equalToConstant: 58),
            jobIconView.heightAnchor.constraint(equalToConstant: 58),

            jobTitleLabel.topAnchor.constraint(equalTo: jobIconView.topAnchor),
            jobTitleLabel.leadingAnchor.constraint(equalTo: jobIconView.trailingAnchor, constant: 14),
            jobTitleLabel.trailingAnchor.constraint(equalTo: jobCardView.trailingAnchor, constant: -18),

            companyLabel.topAnchor.constraint(equalTo: jobTitleLabel.bottomAnchor, constant: 8),
            companyLabel.leadingAnchor.constraint(equalTo: jobTitleLabel.leadingAnchor),
            companyLabel.trailingAnchor.constraint(equalTo: jobTitleLabel.trailingAnchor),
            companyLabel.bottomAnchor.constraint(equalTo: jobCardView.bottomAnchor, constant: -18)
        ])
    }

    private func setupProfileCard() {
        profileCardView.addSubview(profileTitleLabel)
        profileCardView.addSubview(profileDetailsLabel)

        NSLayoutConstraint.activate([
            profileTitleLabel.topAnchor.constraint(equalTo: profileCardView.topAnchor, constant: 16),
            profileTitleLabel.leadingAnchor.constraint(equalTo: profileCardView.leadingAnchor, constant: 16),
            profileTitleLabel.trailingAnchor.constraint(equalTo: profileCardView.trailingAnchor, constant: -16),

            profileDetailsLabel.topAnchor.constraint(equalTo: profileTitleLabel.bottomAnchor, constant: 10),
            profileDetailsLabel.leadingAnchor.constraint(equalTo: profileTitleLabel.leadingAnchor),
            profileDetailsLabel.trailingAnchor.constraint(equalTo: profileTitleLabel.trailingAnchor),
            profileDetailsLabel.bottomAnchor.constraint(equalTo: profileCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupCVCard() {
        cvCardView.addSubview(cvTitleLabel)
        cvCardView.addSubview(cvStatusLabel)
        cvCardView.addSubview(uploadCVButton)

        NSLayoutConstraint.activate([
            cvTitleLabel.topAnchor.constraint(equalTo: cvCardView.topAnchor, constant: 16),
            cvTitleLabel.leadingAnchor.constraint(equalTo: cvCardView.leadingAnchor, constant: 16),
            cvTitleLabel.trailingAnchor.constraint(equalTo: cvCardView.trailingAnchor, constant: -16),

            cvStatusLabel.topAnchor.constraint(equalTo: cvTitleLabel.bottomAnchor, constant: 10),
            cvStatusLabel.leadingAnchor.constraint(equalTo: cvTitleLabel.leadingAnchor),
            cvStatusLabel.trailingAnchor.constraint(equalTo: cvTitleLabel.trailingAnchor),

            uploadCVButton.topAnchor.constraint(equalTo: cvStatusLabel.bottomAnchor, constant: 14),
            uploadCVButton.leadingAnchor.constraint(equalTo: cvTitleLabel.leadingAnchor),
            uploadCVButton.trailingAnchor.constraint(equalTo: cvTitleLabel.trailingAnchor),
            uploadCVButton.heightAnchor.constraint(equalToConstant: 48),
            uploadCVButton.bottomAnchor.constraint(equalTo: cvCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupApplicationCard() {
        applicationCardView.addSubview(applicationTitleLabel)
        applicationCardView.addSubview(applicationDetailsLabel)

        NSLayoutConstraint.activate([
            applicationTitleLabel.topAnchor.constraint(equalTo: applicationCardView.topAnchor, constant: 16),
            applicationTitleLabel.leadingAnchor.constraint(equalTo: applicationCardView.leadingAnchor, constant: 16),
            applicationTitleLabel.trailingAnchor.constraint(equalTo: applicationCardView.trailingAnchor, constant: -16),

            applicationDetailsLabel.topAnchor.constraint(equalTo: applicationTitleLabel.bottomAnchor, constant: 10),
            applicationDetailsLabel.leadingAnchor.constraint(equalTo: applicationTitleLabel.leadingAnchor),
            applicationDetailsLabel.trailingAnchor.constraint(equalTo: applicationTitleLabel.trailingAnchor),
            applicationDetailsLabel.bottomAnchor.constraint(equalTo: applicationCardView.bottomAnchor, constant: -16)
        ])
    }

    private func configure() {
        jobTitleLabel.text = job.title
        companyLabel.text = "\(job.companyName)\n\(job.locationText)"
        profileDetailsLabel.text = profileSummaryText()
        cvStatusLabel.text = cvStatusText()
        applicationDetailsLabel.text = applicationSummaryText()
        submitButton.setTitle(userProfile.cvUrl == nil ? "Submit Without CV" : "Submit Application", for: .normal)
    }

    private func profileSummaryText() -> String {
        return [
            userProfile.name,
            userProfile.email,
            userProfile.location,
            userProfile.jobTitle,
            "Skills: \(userProfile.skills.joined(separator: ", "))"
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != "Skills: " }
        .joined(separator: "\n")
    }

    private func cvStatusText() -> String {
        if let fileName = userProfile.cvFileName, !fileName.isEmpty {
            return "CV attached: \(fileName)"
        }

        if userProfile.cvUrl != nil {
            return "CV attached"
        }

        return "No CV attached"
    }

    private func applicationSummaryText() -> String {
        return [
            "Status: Ready to submit",
            "Job type: \(job.jobType)",
            "Salary: \(job.salaryText)",
            "Deadline: \(job.application.deadline)"
        ].joined(separator: "\n")
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

    private func makeSecondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.10)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc private func uploadCVTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc private func submitTapped() {
        guard !isSubmitting else { return }
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showAlert(title: "Create Profile", message: "Create your profile to apply for this job.")
            return
        }

        guard user.uid == userProfile.uid else {
            showAlert(title: "Account Error", message: "Please sign in again before applying.")
            return
        }

        setSubmitting(true)

        firestoreService.createApplication(userProfile: userProfile, job: job) { [weak self] result in
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
        submitButton.isEnabled = !submitting
        uploadCVButton.isEnabled = !submitting
        submitButton.backgroundColor = submitting ? .systemGray : .systemGreen
        submitButton.setTitle(submitting ? "Submitting..." : (userProfile.cvUrl == nil ? "Submit Without CV" : "Submit Application"), for: .normal)
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Application Submitted",
            message: "Your application for \(job.title) has been submitted.",
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

extension ApplyConfirmationViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        uploadCVButton.isEnabled = false
        uploadCVButton.setTitle("Uploading CV...", for: .normal)

        firestoreService.uploadCVDocument(uid: userProfile.uid, fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.uploadCVButton.isEnabled = true
                self.uploadCVButton.setTitle("Upload CV PDF", for: .normal)

                switch result {
                case .success(let upload):
                    self.saveUploadedCV(url: upload.url, fileName: upload.fileName)
                case .failure(let error):
                    self.showAlert(title: "CV Upload Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func saveUploadedCV(url: String, fileName: String) {
        firestoreService.updateUserCV(uid: userProfile.uid, cvUrl: url, cvFileName: fileName) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(title: "CV Save Failed", message: error.localizedDescription)
                    return
                }

                self.userProfile.cvUrl = url
                self.userProfile.cvFileName = fileName
                self.configure()
                self.showAlert(title: "CV Attached", message: "Your CV is ready for this application.")
            }
        }
    }
}
