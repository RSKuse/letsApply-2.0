//
//  CVBuilderViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth
import UniformTypeIdentifiers

class CVBuilderViewController: UIViewController {

    private let firestoreService = FirestoreService()
    private var currentProfile = UserProfile()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "CV Builder"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Upload your real CV and keep a clean profile-based draft ready for applications."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cvStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "No CV uploaded yet"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var uploadCVButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload CV PDF", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(uploadCVTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var profilePreviewLabel: UILabel = {
        let label = UILabel()
        label.text = "Complete your profile to generate a stronger CV draft."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.backgroundColor = .secondarySystemBackground
        label.layer.cornerRadius = 14
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryTextView: UITextView = {
        let textView = UITextView()
        textView.text = "Professional summary"
        textView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 14
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var saveDraftButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save CV Draft", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveDraftTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "CV"
        setupUI()
        fetchProfile()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(cvStatusLabel)
        view.addSubview(uploadCVButton)
        view.addSubview(profilePreviewLabel)
        view.addSubview(summaryTextView)
        view.addSubview(saveDraftButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            cvStatusLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            cvStatusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            cvStatusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            uploadCVButton.topAnchor.constraint(equalTo: cvStatusLabel.bottomAnchor, constant: 12),
            uploadCVButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            uploadCVButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            uploadCVButton.heightAnchor.constraint(equalToConstant: 52),

            profilePreviewLabel.topAnchor.constraint(equalTo: uploadCVButton.bottomAnchor, constant: 18),
            profilePreviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            profilePreviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            profilePreviewLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 90),

            summaryTextView.topAnchor.constraint(equalTo: profilePreviewLabel.bottomAnchor, constant: 18),
            summaryTextView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            summaryTextView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            summaryTextView.heightAnchor.constraint(equalToConstant: 180),

            saveDraftButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            saveDraftButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            saveDraftButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            saveDraftButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func fetchProfile() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            cvStatusLabel.text = "Create a profile to upload and manage your CV."
            uploadCVButton.isEnabled = false
            return
        }

        firestoreService.fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if case .success(let profile) = result {
                    self.currentProfile = profile
                    self.cvStatusLabel.text = profile.cvFileName.map { "CV uploaded: \($0)" } ?? "No CV uploaded yet"
                    self.summaryTextView.text = profile.professionalSummary.isEmpty ? "Professional summary" : profile.professionalSummary
                    self.profilePreviewLabel.text = self.cvPreviewText(for: profile)
                }
            }
        }
    }

    private func cvPreviewText(for profile: UserProfile) -> String {
        return [
            profile.name,
            profile.jobTitle,
            profile.location,
            "Skills: \(profile.skills.joined(separator: ", "))",
            "Qualifications: \(profile.qualifications.joined(separator: ", "))",
            "Experience: \(profile.experience)",
            "Education: \(profile.education)"
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != "Skills: " && $0 != "Qualifications: " }
        .joined(separator: "\n")
    }

    @objc private func uploadCVTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc private func saveDraftTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showAlert(title: "Create Profile", message: "Create your profile before saving a CV draft.")
            return
        }

        currentProfile.professionalSummary = summaryTextView.text == "Professional summary" ? "" : summaryTextView.text
        firestoreService.saveUserProfile(currentProfile) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Save Failed", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "CV Draft Saved", message: "Your CV draft has been saved to your profile.")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension CVBuilderViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let user = Auth.auth().currentUser, !user.isAnonymous, let fileURL = urls.first else { return }

        uploadCVButton.isEnabled = false
        uploadCVButton.setTitle("Uploading CV...", for: .normal)

        firestoreService.uploadCVDocument(uid: user.uid, fileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.uploadCVButton.isEnabled = true
                self.uploadCVButton.setTitle("Upload CV PDF", for: .normal)

                switch result {
                case .success(let upload):
                    self.firestoreService.updateUserCV(uid: user.uid, cvUrl: upload.url, cvFileName: upload.fileName) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.showAlert(title: "CV Save Failed", message: error.localizedDescription)
                                return
                            }

                            self.currentProfile.cvUrl = upload.url
                            self.currentProfile.cvFileName = upload.fileName
                            self.cvStatusLabel.text = "CV uploaded: \(upload.fileName)"
                            self.showAlert(title: "CV Uploaded", message: "Your CV will attach to new applications.")
                        }
                    }
                case .failure(let error):
                    self.showAlert(title: "CV Upload Failed", message: error.localizedDescription)
                }
            }
        }
    }
}
