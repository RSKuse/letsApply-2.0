//
//  ProfileViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth
import UniformTypeIdentifiers

class ProfileViewController: UIViewController {

    var isProfileSetupMode = false

    private let firestoreService = FirestoreService()
    private let imagePickerService = ImagePickerService()
    private var currentProfile = UserProfile()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headerView,
            statsStackView,
            completionCardView,
            nameTextField,
            emailTextField,
            locationTextField,
            jobTitleTextField,
            professionalSummaryTextView,
            skillsTextField,
            qualificationsTextField,
            experienceTextField,
            educationTextField,
            cvStatusLabel,
            uploadCVButton,
            cvButton,
            applicationsButton,
            savedJobsButton,
            saveButton,
            createProfileButton,
            logoutButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        imageView.tintColor = .systemGreen
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.10)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var headerNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Guest User"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Complete your profile to apply."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var completionCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.10)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var completionStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Profile 0% complete"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var completionMissingLabel: UILabel = {
        let label = UILabel()
        label.text = "Add your details to unlock applications."
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var applicationsStatLabel = makeStatLabel(title: "Applications", value: "0")
    private lazy var savedJobsStatLabel = makeStatLabel(title: "Saved Jobs", value: "0")
    private lazy var premiumStatLabel = makeStatLabel(title: "Plan", value: "Free")

    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            applicationsStatLabel,
            savedJobsStatLabel,
            premiumStatLabel
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    private lazy var nameTextField = makeTextField(placeholder: "Full name")
    private lazy var emailTextField = makeTextField(placeholder: "Email", keyboardType: .emailAddress)
    private lazy var locationTextField = makeTextField(placeholder: "Location")
    private lazy var jobTitleTextField = makeTextField(placeholder: "Desired job title")
    private lazy var professionalSummaryTextView = makeTextView(placeholder: "Professional summary")
    private lazy var skillsTextField = makeTextField(placeholder: "Skills comma separated")
    private lazy var qualificationsTextField = makeTextField(placeholder: "Certificates, licences, qualifications")
    private lazy var experienceTextField = makeTextField(placeholder: "Experience")
    private lazy var educationTextField = makeTextField(placeholder: "Education history")

    private lazy var cvStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "No CV uploaded yet"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var uploadCVButton: UIButton = {
        let button = makeSecondaryButton(title: "Upload CV PDF")
        button.addTarget(self, action: #selector(uploadCVTapped), for: .touchUpInside)
        return button
    }()

    private lazy var cvButton: UIButton = {
        let button = makeSecondaryButton(title: "CV Builder")
        button.addTarget(self, action: #selector(openCVBuilder), for: .touchUpInside)
        return button
    }()

    private lazy var applicationsButton: UIButton = {
        let button = makeSecondaryButton(title: "My Applications")
        button.addTarget(self, action: #selector(openApplications), for: .touchUpInside)
        return button
    }()

    private lazy var savedJobsButton: UIButton = {
        let button = makeSecondaryButton(title: "Saved Jobs")
        button.addTarget(self, action: #selector(openSavedJobs), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var createProfileButton: UIButton = {
        let button = makeSecondaryButton(title: "Create Profile")
        button.addTarget(self, action: #selector(createProfileTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isProfileSetupMode ? "Complete Profile" : "Profile"
        view.backgroundColor = .systemBackground
        imagePickerService.delegate = self
        setupNavigationBar()
        setupUI()
        fetchProfileData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfileStats()
    }

    private func setupNavigationBar() {
        guard isProfileSetupMode else { return }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Home",
            style: .plain,
            target: self,
            action: #selector(homeTapped)
        )
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        headerView.addSubview(profileImageView)
        headerView.addSubview(headerNameLabel)
        headerView.addSubview(headerSubtitleLabel)
        completionCardView.addSubview(completionStatusLabel)
        completionCardView.addSubview(completionMissingLabel)

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePhotoTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTapGesture)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 18),
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 18),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),

            headerNameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 22),
            headerNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            headerNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -18),

            headerSubtitleLabel.topAnchor.constraint(equalTo: headerNameLabel.bottomAnchor, constant: 6),
            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerNameLabel.leadingAnchor),
            headerSubtitleLabel.trailingAnchor.constraint(equalTo: headerNameLabel.trailingAnchor),
            headerSubtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor, constant: -18),
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 118),

            completionStatusLabel.topAnchor.constraint(equalTo: completionCardView.topAnchor, constant: 16),
            completionStatusLabel.leadingAnchor.constraint(equalTo: completionCardView.leadingAnchor, constant: 16),
            completionStatusLabel.trailingAnchor.constraint(equalTo: completionCardView.trailingAnchor, constant: -16),

            completionMissingLabel.topAnchor.constraint(equalTo: completionStatusLabel.bottomAnchor, constant: 8),
            completionMissingLabel.leadingAnchor.constraint(equalTo: completionStatusLabel.leadingAnchor),
            completionMissingLabel.trailingAnchor.constraint(equalTo: completionStatusLabel.trailingAnchor),
            completionMissingLabel.bottomAnchor.constraint(equalTo: completionCardView.bottomAnchor, constant: -16),

            saveButton.heightAnchor.constraint(equalToConstant: 52),
            createProfileButton.heightAnchor.constraint(equalToConstant: 48),
            uploadCVButton.heightAnchor.constraint(equalToConstant: 48),
            cvButton.heightAnchor.constraint(equalToConstant: 48),
            applicationsButton.heightAnchor.constraint(equalToConstant: 48),
            savedJobsButton.heightAnchor.constraint(equalToConstant: 48),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeTextField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> UITextField {
        let textField = UITextField()
        textField.configureTextField(placeholder: placeholder, keyboardType: keyboardType)
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }

    private func makeTextView(placeholder: String) -> UITextView {
        let textView = UITextView()
        textView.text = placeholder
        textView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .secondaryLabel
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 10
        textView.layer.borderColor = UIColor.systemGray5.cgColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self
        textView.heightAnchor.constraint(equalToConstant: 110).isActive = true
        return textView
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

    private func makeStatLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        label.text = "\(value)\n\(title)"
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = .secondarySystemBackground
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return label
    }

    private func fetchProfileData() {
        guard let user = Auth.auth().currentUser else {
            configureGuestProfile()
            return
        }

        if user.isAnonymous {
            configureGuestProfile()
            return
        }

        firestoreService.fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let profile):
                    self.currentProfile = profile
                    self.populateProfile(profile)
                case .failure(let error):
                    self.showAlert(title: "Profile Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func configureGuestProfile() {
        currentProfile = UserProfile(
            uid: Auth.auth().currentUser?.uid ?? "",
            name: "Guest User",
            email: "",
            location: "South Africa",
            profilePictureUrl: nil,
            cvUrl: nil,
            cvFileName: nil,
            professionalSummary: "",
            jobTitle: "",
            skills: [],
            qualifications: [],
            experience: "",
            education: "",
            savedJobs: [],
            isPremium: false
        )
        populateProfile(currentProfile)
        saveButton.isHidden = true
        createProfileButton.isHidden = false
        logoutButton.setTitle("Exit Guest Mode", for: .normal)
    }

    private func populateProfile(_ profile: UserProfile) {
        headerNameLabel.text = profile.name.isEmpty ? "Complete your profile" : profile.name
        headerSubtitleLabel.text = profile.isComplete ? profile.jobTitle : "Complete your profile to unlock applications."

        nameTextField.text = profile.name
        emailTextField.text = profile.email.isEmpty ? FirebaseAuthenticationService.shared.currentUserEmail : profile.email
        locationTextField.text = profile.location
        jobTitleTextField.text = profile.jobTitle
        professionalSummaryTextView.text = profile.professionalSummary.isEmpty ? "Professional summary" : profile.professionalSummary
        professionalSummaryTextView.textColor = profile.professionalSummary.isEmpty ? .secondaryLabel : .label
        skillsTextField.text = profile.skills.joined(separator: ", ")
        qualificationsTextField.text = profile.qualifications.joined(separator: ", ")
        experienceTextField.text = profile.experience
        educationTextField.text = profile.education
        premiumStatLabel.text = "\(profile.isPremium ? "Premium" : "Free")\nPlan"
        cvStatusLabel.text = profile.cvFileName.map { "CV uploaded: \($0)" } ?? "No CV uploaded yet"
        updateCompletionUI(profile)

        if let profilePictureUrl = profile.profilePictureUrl {
            ProfilePictureService.shared.fetchProfilePicture(urlString: profilePictureUrl) { [weak self] image in
                self?.profileImageView.image = image ?? UIImage(systemName: "person.circle.fill")
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        saveButton.isHidden = false
        createProfileButton.isHidden = true
    }

    private func updateCompletionUI(_ profile: UserProfile) {
        completionStatusLabel.text = "Profile \(profile.completionPercentage)% complete"

        if profile.isComplete {
            completionCardView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            completionMissingLabel.text = profile.cvUrl == nil
            ? "You can apply now. Uploading a CV will make each application stronger."
            : "Ready to apply. Your CV will be attached to new applications."
        } else {
            completionCardView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            completionMissingLabel.text = "Missing: \(profile.missingRequiredFields.joined(separator: ", "))"
        }
    }

    private func fetchProfileStats() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            applicationsStatLabel.text = "0\nApplications"
            savedJobsStatLabel.text = "0\nSaved Jobs"
            return
        }

        firestoreService.fetchApplications(userId: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let applications) = result {
                    self?.applicationsStatLabel.text = "\(applications.count)\nApplications"
                }
            }
        }

        firestoreService.fetchSavedJobs(userId: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let savedJobs) = result {
                    self?.savedJobsStatLabel.text = "\(savedJobs.count)\nSaved Jobs"
                }
            }
        }
    }

    private func parseList(_ text: String?) -> [String] {
        return (text ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @objc private func saveProfile() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        let profile = UserProfile(
            uid: user.uid,
            name: nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            email: emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? user.email ?? "",
            location: locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            profilePictureUrl: currentProfile.profilePictureUrl,
            cvUrl: currentProfile.cvUrl,
            cvFileName: currentProfile.cvFileName,
            professionalSummary: professionalSummaryText(),
            jobTitle: jobTitleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            skills: parseList(skillsTextField.text),
            qualifications: parseList(qualificationsTextField.text),
            experience: experienceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            education: educationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            savedJobs: currentProfile.savedJobs,
            isPremium: currentProfile.isPremium
        )

        saveButton.isEnabled = false

        firestoreService.saveUserProfile(profile) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.saveButton.isEnabled = true

                if let error = error {
                    self.showAlert(title: "Save Failed", message: error.localizedDescription)
                    return
                }

                self.currentProfile = profile
                self.populateProfile(profile)

                let message = profile.isComplete ? "Your profile is complete. You can now apply for jobs." : "Saved. Add the missing details before applying."
                self.showAlert(title: "Profile Saved", message: message)
            }
        }
    }

    private func professionalSummaryText() -> String {
        let text = professionalSummaryTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text == "Professional summary" ? "" : text
    }

    @objc private func changeProfilePhotoTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        imagePickerService.presentImagePicker(from: self)
    }

    @objc private func uploadCVTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc private func openCVBuilder() {
        let cvVC = CVBuilderViewController()
        cvVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(cvVC, animated: true)
    }

    @objc private func openApplications() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        let applicationsVC = ApplicationsViewController(userId: user.uid)
        applicationsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(applicationsVC, animated: true)
    }

    @objc private func openSavedJobs() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        let savedJobsVC = SavedJobsViewController(userId: user.uid)
        savedJobsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(savedJobsVC, animated: true)
    }

    @objc private func createProfileTapped() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func homeTapped() {
        tabBarController?.selectedIndex = 0
    }

    @objc private func logout() {
        FirebaseAuthenticationService.shared.signOut { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Logout Failed", message: error.localizedDescription)
                } else {
                    AppRouter.showOnboarding()
                }
            }
        }
    }

    private func showRegistrationPrompt() {
        let alert = UIAlertController(
            title: "Create Profile",
            message: "Create your profile to save your career details.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Register", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(SignUpViewController(), animated: true)
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

extension ProfileViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Professional summary" {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Professional summary"
            textView.textColor = .secondaryLabel
        }
    }
}

extension ProfileViewController: ImagePickerDelegate {

    func didSelectImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else { return }

        profileImageView.image = image
        ProfilePictureService.shared.uploadProfilePicture(uid: user.uid, image: image) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let url):
                    self.currentProfile.profilePictureUrl = url
                    self.saveProfile()
                case .failure(let error):
                    self.showAlert(title: "Photo Upload Failed", message: error.localizedDescription)
                }
            }
        }
    }
}

extension ProfileViewController: UIDocumentPickerDelegate {

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
                            self.updateCompletionUI(self.currentProfile)
                            self.showAlert(title: "CV Uploaded", message: "Your CV will attach to new job applications.")
                        }
                    }
                case .failure(let error):
                    self.showAlert(title: "CV Upload Failed", message: error.localizedDescription)
                }
            }
        }
    }
}
