//
//  CVBuilderViewController.swift
//  letsApply
//

import FirebaseAuth
import UIKit
import UniformTypeIdentifiers

class CVBuilderViewController: UIViewController {

    private let firestoreService = FirestoreService()
    private let pdfService = CVPDFService()
    private var currentProfile = UserProfile()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            introStackView,
            templateCardView,
            profileCardView,
            summaryCardView,
            localModeCardView,
            saveDraftButton,
            uploadCVButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var introStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "CV Studio"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Build a polished CV from your profile, then preview and share it as a PDF."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private lazy var templateCardView = makeCardView(backgroundColor: AppTheme.ink)
    private lazy var profileCardView = makeCardView()
    private lazy var summaryCardView = makeCardView()
    private lazy var localModeCardView = makeCardView(backgroundColor: AppTheme.mutedSurface)

    private lazy var templateIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "doc.richtext.fill"))
        imageView.tintColor = AppTheme.ink
        imageView.backgroundColor = AppTheme.brandBright
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = AppTheme.cardRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var templateNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Modern Professional"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var templateDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Clear sections  |  ATS-friendly  |  Local PDF"
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.64)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var templateStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "ACTIVE TEMPLATE"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = AppTheme.cyan
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var profileTitleLabel = makeSectionTitleLabel(text: "Profile Content")

    private lazy var profilePreviewLabel: UILabel = {
        let label = UILabel()
        label.text = "Complete your profile to generate a stronger CV."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryTitleLabel = makeSectionTitleLabel(text: "Professional Summary")

    private lazy var summaryTextView: UITextView = {
        let textView = UITextView()
        textView.text = "Professional summary"
        textView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.background
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderWidth = 1
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var localModeIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        imageView.tintColor = AppTheme.brand
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var localModeLabel: UILabel = {
        let label = UILabel()
        label.text = "Free local mode\nYour PDF is created on this device. Firebase Storage is not required."
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var saveDraftButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = "Save Profile Changes"
        configuration.image = UIImage(systemName: "checkmark")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.addTarget(self, action: #selector(saveDraftTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var uploadCVButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = "Upload Existing PDF"
        configuration.image = UIImage(systemName: "arrow.up.doc")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.addTarget(self, action: #selector(uploadCVTapped), for: .touchUpInside)
        button.isHidden = !AppFeatures.firebaseStorageUploadsEnabled
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var previewButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Preview CV",
            systemImageName: "doc.text.magnifyingglass"
        )
        button.isEnabled = false
        button.addTarget(self, action: #selector(previewCVTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = "CV"
        setupUI()
        setupTemplateCard()
        setupProfileCard()
        setupSummaryCard()
        setupLocalModeCard()
        fetchProfile()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(previewButton)
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: previewButton.topAnchor, constant: -12),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            saveDraftButton.heightAnchor.constraint(equalToConstant: 50),
            uploadCVButton.heightAnchor.constraint(equalToConstant: 50),

            previewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            previewButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func setupTemplateCard() {
        templateCardView.addSubview(templateIconView)
        templateCardView.addSubview(templateNameLabel)
        templateCardView.addSubview(templateDetailLabel)
        templateCardView.addSubview(templateStatusLabel)

        NSLayoutConstraint.activate([
            templateCardView.heightAnchor.constraint(equalToConstant: 132),

            templateIconView.topAnchor.constraint(equalTo: templateCardView.topAnchor, constant: 18),
            templateIconView.leadingAnchor.constraint(equalTo: templateCardView.leadingAnchor, constant: 18),
            templateIconView.widthAnchor.constraint(equalToConstant: 50),
            templateIconView.heightAnchor.constraint(equalToConstant: 50),

            templateStatusLabel.centerYAnchor.constraint(equalTo: templateIconView.centerYAnchor),
            templateStatusLabel.leadingAnchor.constraint(equalTo: templateIconView.trailingAnchor, constant: 12),
            templateStatusLabel.trailingAnchor.constraint(equalTo: templateCardView.trailingAnchor, constant: -18),

            templateNameLabel.leadingAnchor.constraint(equalTo: templateIconView.leadingAnchor),
            templateNameLabel.trailingAnchor.constraint(equalTo: templateCardView.trailingAnchor, constant: -18),
            templateNameLabel.topAnchor.constraint(equalTo: templateIconView.bottomAnchor, constant: 15),

            templateDetailLabel.leadingAnchor.constraint(equalTo: templateNameLabel.leadingAnchor),
            templateDetailLabel.trailingAnchor.constraint(equalTo: templateNameLabel.trailingAnchor),
            templateDetailLabel.topAnchor.constraint(equalTo: templateNameLabel.bottomAnchor, constant: 5)
        ])
    }

    private func setupProfileCard() {
        profileCardView.addSubview(profileTitleLabel)
        profileCardView.addSubview(profilePreviewLabel)

        NSLayoutConstraint.activate([
            profileTitleLabel.topAnchor.constraint(equalTo: profileCardView.topAnchor, constant: 16),
            profileTitleLabel.leadingAnchor.constraint(equalTo: profileCardView.leadingAnchor, constant: 16),
            profileTitleLabel.trailingAnchor.constraint(equalTo: profileCardView.trailingAnchor, constant: -16),

            profilePreviewLabel.topAnchor.constraint(equalTo: profileTitleLabel.bottomAnchor, constant: 10),
            profilePreviewLabel.leadingAnchor.constraint(equalTo: profileTitleLabel.leadingAnchor),
            profilePreviewLabel.trailingAnchor.constraint(equalTo: profileTitleLabel.trailingAnchor),
            profilePreviewLabel.bottomAnchor.constraint(equalTo: profileCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupSummaryCard() {
        summaryCardView.addSubview(summaryTitleLabel)
        summaryCardView.addSubview(summaryTextView)

        NSLayoutConstraint.activate([
            summaryTitleLabel.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 16),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),

            summaryTextView.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 10),
            summaryTextView.leadingAnchor.constraint(equalTo: summaryTitleLabel.leadingAnchor),
            summaryTextView.trailingAnchor.constraint(equalTo: summaryTitleLabel.trailingAnchor),
            summaryTextView.heightAnchor.constraint(equalToConstant: 190),
            summaryTextView.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupLocalModeCard() {
        localModeCardView.addSubview(localModeIconView)
        localModeCardView.addSubview(localModeLabel)

        NSLayoutConstraint.activate([
            localModeIconView.leadingAnchor.constraint(equalTo: localModeCardView.leadingAnchor, constant: 16),
            localModeIconView.centerYAnchor.constraint(equalTo: localModeCardView.centerYAnchor),
            localModeIconView.widthAnchor.constraint(equalToConstant: 30),
            localModeIconView.heightAnchor.constraint(equalToConstant: 30),

            localModeLabel.topAnchor.constraint(equalTo: localModeCardView.topAnchor, constant: 14),
            localModeLabel.leadingAnchor.constraint(equalTo: localModeIconView.trailingAnchor, constant: 12),
            localModeLabel.trailingAnchor.constraint(equalTo: localModeCardView.trailingAnchor, constant: -16),
            localModeLabel.bottomAnchor.constraint(equalTo: localModeCardView.bottomAnchor, constant: -14)
        ])
    }

    private func fetchProfile() {
        #if DEBUG
        if loadDebugProfileIfNeeded() {
            return
        }
        #endif

        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            profilePreviewLabel.text = "Create a profile to build and export your CV."
            return
        }

        firestoreService.fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let profile):
                    self.configure(with: profile)
                case .failure(let error):
                    self.showAlert(title: "Profile Not Loaded", message: error.localizedDescription)
                }
            }
        }
    }

    private func configure(with profile: UserProfile) {
        currentProfile = profile
        summaryTextView.text = profile.professionalSummary.isEmpty
            ? "Professional summary"
            : profile.professionalSummary
        profilePreviewLabel.text = cvPreviewText(for: profile)
        previewButton.isEnabled = true
        openDebugPreviewIfNeeded()
    }

    private func cvPreviewText(for profile: UserProfile) -> String {
        let skillsText = profile.skills.isEmpty
            ? "Skills still needed"
            : "\(profile.skills.count) skills ready"
        let qualificationsText = profile.qualifications.isEmpty
            ? "Qualifications still needed"
            : "\(profile.qualifications.count) qualifications ready"

        return [
            profile.name,
            profile.jobTitle,
            profile.location,
            skillsText,
            qualificationsText,
            profile.experience.isEmpty ? "Experience still needed" : "Experience ready",
            profile.education.isEmpty ? "Education still needed" : "Education ready"
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n")
    }

    private func updateProfileSummary() {
        let summary = summaryTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentProfile.professionalSummary = summary == "Professional summary" ? "" : summary
    }

    private func openDebugPreviewIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["LETSAPPLY_AUTO_PREVIEW_CV"] == "1" else {
            return
        }

        previewCVTapped()
        #endif
    }

    #if DEBUG
    private func loadDebugProfileIfNeeded() -> Bool {
        guard ProcessInfo.processInfo.environment["LETSAPPLY_AUTO_PREVIEW_CV"] == "1" else {
            return false
        }

        let profile = UserProfile(
            name: "Amina Ndlovu",
            email: "amina@example.com",
            location: "Johannesburg, South Africa",
            professionalSummary: """
            Accomplished Senior Software Engineer with over a decade of experience building \
            high-performing, scalable, and secure platforms. Expert in system architecture, \
            cloud computing, and leading cross-functional teams to deliver reliable products.
            """,
            jobTitle: "Software Developer",
            skills: [
                "Swift", "UIKit", "JavaScript", "Python", "Java", "TypeScript",
                "React", "Node.js", "AWS", "Git", "Docker", "Firebase"
            ],
            qualifications: [
                "Software Development Certificate",
                "AWS Cloud Practitioner",
                "Agile Project Management",
                "Professional Communication"
            ],
            experience: """
            Senior Software Developer: Designed and delivered mobile and cloud applications \
            using Swift, Firebase, and modern API architecture. Led feature development, code \
            reviews, release planning, and performance improvements across product teams.

            Software Developer: Built reusable UIKit components, integrated authentication and \
            Firestore data services, and improved application stability through focused testing.
            """,
            education: """
            Bachelor of Computer Science: Software Engineering, application architecture, \
            databases, and distributed systems.

            Additional Training: iOS development, cloud computing, and product design.
            """
        )
        configure(with: profile)
        return true
    }
    #endif

    private func makeCardView(backgroundColor: UIColor = AppTheme.surface) -> UIView {
        let view = UIView()
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = backgroundColor == AppTheme.ink ? 0 : 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func makeSectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    @objc private func previewCVTapped() {
        updateProfileSummary()

        do {
            let pdfURL = try pdfService.generateCV(for: currentProfile)
            let previewViewController = CVPreviewViewController(pdfURL: pdfURL)
            previewViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(previewViewController, animated: true)
        } catch {
            showAlert(title: "CV Not Generated", message: error.localizedDescription)
        }
    }

    @objc private func saveDraftTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showAlert(title: "Create Profile", message: "Create your profile before saving CV changes.")
            return
        }

        updateProfileSummary()
        firestoreService.saveUserProfile(currentProfile) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(title: "Save Failed", message: error.localizedDescription)
                } else {
                    self?.showAlert(
                        title: "CV Profile Saved",
                        message: "Your latest profile content is ready for future CVs."
                    )
                }
            }
        }
    }

    @objc private func uploadCVTapped() {
        guard AppFeatures.firebaseStorageUploadsEnabled else {
            showAlert(title: "PDF Upload Paused", message: AppFeatures.storagePausedMessage)
            return
        }

        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf],
            asCopy: true
        )
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension CVBuilderViewController: UIDocumentPickerDelegate {

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard AppFeatures.firebaseStorageUploadsEnabled else {
            showAlert(title: "PDF Upload Paused", message: AppFeatures.storagePausedMessage)
            return
        }

        guard let user = Auth.auth().currentUser,
              !user.isAnonymous,
              let fileURL = urls.first else {
            return
        }

        uploadCVButton.isEnabled = false
        uploadCVButton.configuration?.title = "Uploading CV..."

        firestoreService.uploadCVDocument(uid: user.uid, fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.uploadCVButton.isEnabled = true
                self.uploadCVButton.configuration?.title = "Upload Existing PDF"

                switch result {
                case .success(let upload):
                    self.firestoreService.updateUserCV(
                        uid: user.uid,
                        cvUrl: upload.url,
                        cvFileName: upload.fileName
                    ) { error in
                        DispatchQueue.main.async {
                            if let error {
                                self.showAlert(title: "CV Save Failed", message: error.localizedDescription)
                            } else {
                                self.currentProfile.cvUrl = upload.url
                                self.currentProfile.cvFileName = upload.fileName
                                self.showAlert(
                                    title: "CV Uploaded",
                                    message: "Your uploaded CV is ready for new applications."
                                )
                            }
                        }
                    }
                case .failure(let error):
                    self.showAlert(title: "CV Upload Failed", message: error.localizedDescription)
                }
            }
        }
    }
}
