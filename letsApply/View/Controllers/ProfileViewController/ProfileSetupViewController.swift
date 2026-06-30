//
//  ProfileViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    var isProfileSetupMode = false
    #if DEBUG
    var debugProfile: UserProfile?
    #endif

    private let firestoreService = FirestoreService()
    private let adminAccessService = AdminAccessService()
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
            identityCardView,
            targetRoleCardView,
            summaryCardView,
            saveButton,
            cvStudioCardView,
            applicationsButton,
            savedJobsButton,
            createProfileButton,
            privacyButton,
            deleteAccountButton,
            logoutButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        imageView.tintColor = AppTheme.brand
        imageView.backgroundColor = AppTheme.mutedSurface
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
        view.backgroundColor = AppTheme.mutedSurface
        view.layer.cornerRadius = AppTheme.cardRadius
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
    private lazy var phoneTextField = makeTextField(placeholder: "Phone number", keyboardType: .phonePad)
    private lazy var locationTextField = makeTextField(placeholder: "Location")
    private lazy var jobTitleTextField = makeTextField(placeholder: "e.g. Risk Analyst")
    private lazy var professionalSummaryTextView = makeTextView(placeholder: "Professional summary")

    private lazy var identityCardView = makeCardView()
    private lazy var targetRoleCardView = makeCardView()
    private lazy var summaryCardView = makeCardView()

    private lazy var identityTitleLabel = makeSectionTitleLabel(
        title: "Career Identity",
        subtitle: "Your contact details"
    )

    private lazy var identityFieldsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makeFieldGroup(title: "Full Name", field: nameTextField),
            makeFieldGroup(title: "Email", field: emailTextField),
            makeFieldGroup(title: "Phone", field: phoneTextField),
            makeFieldGroup(title: "Location", field: locationTextField)
        ])
        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var targetRoleIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "scope"))
        imageView.tintColor = AppTheme.brand
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var targetRoleTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Default Target Role"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var targetRoleDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Job matching starts here. Each application uses the vacancy title automatically."
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryTitleLabel = makeSectionTitleLabel(
        title: "Professional Summary",
        subtitle: "Your reusable career story"
    )

    private lazy var cvStudioCardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.ink
        view.layer.cornerRadius = AppTheme.cardRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = "CV Studio"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openCVBuilder))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var cvStudioIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass"))
        imageView.tintColor = AppTheme.ink
        imageView.backgroundColor = AppTheme.brandBright
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = AppTheme.cardRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var cvStudioTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "CV Studio"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cvStudioStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Checking CV readiness"
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.68)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cvStudioArrowView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "arrow.right"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var cvProgressTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cvProgressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.brandBright
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var cvProgressWidthConstraint: NSLayoutConstraint?

    private lazy var applicationsButton: UIButton = {
        let button = makeSecondaryButton(
            title: "My Applications",
            systemImageName: "tray.full"
        )
        button.addTarget(self, action: #selector(openApplications), for: .touchUpInside)
        return button
    }()

    private lazy var savedJobsButton: UIButton = {
        let button = makeSecondaryButton(
            title: "Saved Jobs",
            systemImageName: "bookmark.fill"
        )
        button.addTarget(self, action: #selector(openSavedJobs), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Save Career Profile",
            systemImageName: "checkmark"
        )
        button.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var createProfileButton: UIButton = {
        let button = makeSecondaryButton(
            title: "Create Profile",
            systemImageName: "person.crop.circle.badge.plus"
        )
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

    private lazy var privacyButton: UIButton = {
        let button = makeSecondaryButton(
            title: "Privacy & Data",
            systemImageName: "hand.raised.fill"
        )
        button.addTarget(self, action: #selector(openPrivacy), for: .touchUpInside)
        return button
    }()

    private lazy var deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Delete Account"
        configuration.image = UIImage(systemName: "trash")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .systemRed
        button.configuration = configuration
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isProfileSetupMode ? "Complete Profile" : "Profile"
        tabBarItem.title = "Profile"
        view.backgroundColor = AppTheme.background
        imagePickerService.delegate = self
        setupNavigationBar()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAdminAccess()
        #if DEBUG
        if let debugProfile {
            currentProfile = debugProfile
            populateProfile(debugProfile)
            return
        }
        #endif
        fetchProfileData()
        fetchProfileStats()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        guard ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_PROFILE_SCROLL"] == "details" else {
            return
        }
        let maximumOffset = max(
            0,
            scrollView.contentSize.height - scrollView.bounds.height
        )
        scrollView.setContentOffset(
            CGPoint(x: 0, y: min(980, maximumOffset)),
            animated: false
        )
        #endif
    }

    private func setupNavigationBar() {
        guard isProfileSetupMode else { return }

        let homeButton = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            style: .plain,
            target: self,
            action: #selector(homeTapped)
        )
        homeButton.accessibilityLabel = "Home"
        navigationItem.rightBarButtonItem = homeButton
    }

    private func configureAdminAccess() {
        guard !isProfileSetupMode else { return }

        adminAccessService.checkAccess { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                guard case .success(true) = result else {
                    self.navigationItem.rightBarButtonItem = nil
                    return
                }

                let adminButton = UIBarButtonItem(
                    image: UIImage(systemName: "briefcase.fill"),
                    style: .plain,
                    target: self,
                    action: #selector(self.openAdminJobs)
                )
                adminButton.accessibilityLabel = "Manage jobs"
                self.navigationItem.rightBarButtonItem = adminButton
            }
        }
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        headerView.addSubview(profileImageView)
        headerView.addSubview(headerNameLabel)
        headerView.addSubview(headerSubtitleLabel)
        completionCardView.addSubview(completionStatusLabel)
        completionCardView.addSubview(completionMissingLabel)

        identityCardView.addSubview(identityTitleLabel)
        identityCardView.addSubview(identityFieldsStackView)

        targetRoleCardView.addSubview(targetRoleIconView)
        targetRoleCardView.addSubview(targetRoleTitleLabel)
        targetRoleCardView.addSubview(targetRoleDetailLabel)
        targetRoleCardView.addSubview(jobTitleTextField)

        summaryCardView.addSubview(summaryTitleLabel)
        summaryCardView.addSubview(professionalSummaryTextView)

        cvStudioCardView.addSubview(cvStudioIconView)
        cvStudioCardView.addSubview(cvStudioTitleLabel)
        cvStudioCardView.addSubview(cvStudioStatusLabel)
        cvStudioCardView.addSubview(cvStudioArrowView)
        cvStudioCardView.addSubview(cvProgressTrackView)
        cvProgressTrackView.addSubview(cvProgressFillView)

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

            identityTitleLabel.topAnchor.constraint(equalTo: identityCardView.topAnchor, constant: 18),
            identityTitleLabel.leadingAnchor.constraint(equalTo: identityCardView.leadingAnchor, constant: 18),
            identityTitleLabel.trailingAnchor.constraint(equalTo: identityCardView.trailingAnchor, constant: -18),

            identityFieldsStackView.topAnchor.constraint(equalTo: identityTitleLabel.bottomAnchor, constant: 18),
            identityFieldsStackView.leadingAnchor.constraint(equalTo: identityTitleLabel.leadingAnchor),
            identityFieldsStackView.trailingAnchor.constraint(equalTo: identityTitleLabel.trailingAnchor),
            identityFieldsStackView.bottomAnchor.constraint(equalTo: identityCardView.bottomAnchor, constant: -18),

            targetRoleIconView.topAnchor.constraint(equalTo: targetRoleCardView.topAnchor, constant: 18),
            targetRoleIconView.leadingAnchor.constraint(equalTo: targetRoleCardView.leadingAnchor, constant: 18),
            targetRoleIconView.widthAnchor.constraint(equalToConstant: 24),
            targetRoleIconView.heightAnchor.constraint(equalToConstant: 24),

            targetRoleTitleLabel.centerYAnchor.constraint(equalTo: targetRoleIconView.centerYAnchor),
            targetRoleTitleLabel.leadingAnchor.constraint(equalTo: targetRoleIconView.trailingAnchor, constant: 10),
            targetRoleTitleLabel.trailingAnchor.constraint(equalTo: targetRoleCardView.trailingAnchor, constant: -18),

            targetRoleDetailLabel.topAnchor.constraint(equalTo: targetRoleIconView.bottomAnchor, constant: 10),
            targetRoleDetailLabel.leadingAnchor.constraint(equalTo: targetRoleIconView.leadingAnchor),
            targetRoleDetailLabel.trailingAnchor.constraint(equalTo: targetRoleTitleLabel.trailingAnchor),

            jobTitleTextField.topAnchor.constraint(equalTo: targetRoleDetailLabel.bottomAnchor, constant: 14),
            jobTitleTextField.leadingAnchor.constraint(equalTo: targetRoleDetailLabel.leadingAnchor),
            jobTitleTextField.trailingAnchor.constraint(equalTo: targetRoleDetailLabel.trailingAnchor),
            jobTitleTextField.bottomAnchor.constraint(equalTo: targetRoleCardView.bottomAnchor, constant: -18),

            summaryTitleLabel.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 18),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -18),

            professionalSummaryTextView.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 16),
            professionalSummaryTextView.leadingAnchor.constraint(equalTo: summaryTitleLabel.leadingAnchor),
            professionalSummaryTextView.trailingAnchor.constraint(equalTo: summaryTitleLabel.trailingAnchor),
            professionalSummaryTextView.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -18),

            cvStudioIconView.topAnchor.constraint(equalTo: cvStudioCardView.topAnchor, constant: 18),
            cvStudioIconView.leadingAnchor.constraint(equalTo: cvStudioCardView.leadingAnchor, constant: 18),
            cvStudioIconView.widthAnchor.constraint(equalToConstant: 48),
            cvStudioIconView.heightAnchor.constraint(equalToConstant: 48),

            cvStudioTitleLabel.topAnchor.constraint(equalTo: cvStudioIconView.topAnchor, constant: 1),
            cvStudioTitleLabel.leadingAnchor.constraint(equalTo: cvStudioIconView.trailingAnchor, constant: 14),
            cvStudioTitleLabel.trailingAnchor.constraint(equalTo: cvStudioArrowView.leadingAnchor, constant: -12),

            cvStudioStatusLabel.topAnchor.constraint(equalTo: cvStudioTitleLabel.bottomAnchor, constant: 4),
            cvStudioStatusLabel.leadingAnchor.constraint(equalTo: cvStudioTitleLabel.leadingAnchor),
            cvStudioStatusLabel.trailingAnchor.constraint(equalTo: cvStudioTitleLabel.trailingAnchor),

            cvStudioArrowView.centerYAnchor.constraint(equalTo: cvStudioIconView.centerYAnchor),
            cvStudioArrowView.trailingAnchor.constraint(equalTo: cvStudioCardView.trailingAnchor, constant: -18),
            cvStudioArrowView.widthAnchor.constraint(equalToConstant: 22),
            cvStudioArrowView.heightAnchor.constraint(equalToConstant: 22),

            cvProgressTrackView.topAnchor.constraint(equalTo: cvStudioIconView.bottomAnchor, constant: 16),
            cvProgressTrackView.leadingAnchor.constraint(equalTo: cvStudioIconView.leadingAnchor),
            cvProgressTrackView.trailingAnchor.constraint(equalTo: cvStudioArrowView.trailingAnchor),
            cvProgressTrackView.bottomAnchor.constraint(equalTo: cvStudioCardView.bottomAnchor, constant: -18),
            cvProgressTrackView.heightAnchor.constraint(equalToConstant: 4),

            cvProgressFillView.topAnchor.constraint(equalTo: cvProgressTrackView.topAnchor),
            cvProgressFillView.leadingAnchor.constraint(equalTo: cvProgressTrackView.leadingAnchor),
            cvProgressFillView.bottomAnchor.constraint(equalTo: cvProgressTrackView.bottomAnchor),

            saveButton.heightAnchor.constraint(equalToConstant: 52),
            createProfileButton.heightAnchor.constraint(equalToConstant: 48),
            applicationsButton.heightAnchor.constraint(equalToConstant: 48),
            savedJobsButton.heightAnchor.constraint(equalToConstant: 48),
            privacyButton.heightAnchor.constraint(equalToConstant: 48),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        updateCVProgress(percentage: 0)
    }

    private func makeTextField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> UITextField {
        let textField = UITextField()
        textField.configureTextField(placeholder: placeholder, keyboardType: keyboardType)
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.textColor = .label
        textField.backgroundColor = AppTheme.background
        textField.layer.cornerRadius = AppTheme.cardRadius
        textField.layer.borderColor = AppTheme.border.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return textField
    }

    private func makeTextView(placeholder: String) -> UITextView {
        let textView = UITextView()
        textView.text = placeholder
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = AppTheme.secondaryText
        textView.backgroundColor = AppTheme.background
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        return textView
    }

    private func makeSecondaryButton(
        title: String,
        systemImageName: String? = nil
    ) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = title
        configuration.baseForegroundColor = AppTheme.brand
        configuration.baseBackgroundColor = AppTheme.mutedSurface
        configuration.cornerStyle = .medium
        if let systemImageName {
            configuration.image = UIImage(systemName: systemImageName)
            configuration.imagePlacement = .trailing
            configuration.imagePadding = 10
        }
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            return updatedAttributes
        }
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func makeSectionTitleLabel(title: String, subtitle: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppTheme.secondaryText

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    private func makeFieldGroup(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = AppTheme.secondaryText

        let stackView = UIStackView(arrangedSubviews: [label, field])
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }

    private func makeStatLabel(title: String, value: String) -> UILabel {
        let label = UILabel()
        label.text = "\(value)\n\(title)"
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = AppTheme.surface
        label.layer.cornerRadius = AppTheme.cardRadius
        label.layer.borderWidth = 1
        label.layer.borderColor = AppTheme.border.cgColor
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
        deleteAccountButton.isHidden = true
        logoutButton.setTitle("Exit Guest Mode", for: .normal)
    }

    private func populateProfile(_ profile: UserProfile) {
        headerNameLabel.text = profile.name.isEmpty ? "Complete your profile" : profile.name
        headerSubtitleLabel.text = profile.jobTitle.isEmpty
            ? "Set your target role"
            : profile.jobTitle

        nameTextField.text = profile.name
        emailTextField.text = profile.email.isEmpty ? FirebaseAuthenticationService.shared.currentUserEmail : profile.email
        phoneTextField.text = profile.phone
        locationTextField.text = profile.location
        jobTitleTextField.text = profile.jobTitle
        professionalSummaryTextView.text = profile.professionalSummary.isEmpty ? "Professional summary" : profile.professionalSummary
        professionalSummaryTextView.textColor = profile.professionalSummary.isEmpty ? .secondaryLabel : .label
        premiumStatLabel.text = "\(profile.isPremium ? "Premium" : "Free")\nPlan"
        updateCompletionUI(profile)
        updateCVStudioUI(profile)

        if let profileImageData = profile.profileImageData,
           let image = ProfilePictureService.shared.image(fromFirestoreData: profileImageData) {
            profileImageView.image = image
        } else if let profilePictureUrl = profile.profilePictureUrl {
            ProfilePictureService.shared.fetchProfilePicture(urlString: profilePictureUrl) { [weak self] image in
                self?.profileImageView.image = image ?? UIImage(systemName: "person.circle.fill")
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        saveButton.isHidden = false
        createProfileButton.isHidden = true
        deleteAccountButton.isHidden = false
        logoutButton.setTitle("Logout", for: .normal)
    }

    private func updateCompletionUI(_ profile: UserProfile) {
        let missingFields = missingCareerIdentityFields(for: profile)
        let totalFields = 6
        let completedFields = totalFields - missingFields.count
        let percentage = Int((Double(completedFields) / Double(totalFields)) * 100)
        completionStatusLabel.text = missingFields.isEmpty
            ? "Career identity ready"
            : "Career identity \(percentage)% ready"

        if missingFields.isEmpty {
            completionCardView.backgroundColor = AppTheme.mutedSurface
            completionMissingLabel.text = "Your default role guides discovery. Application Review adapts it to each vacancy."
        } else {
            completionCardView.backgroundColor = AppTheme.amber.withAlphaComponent(0.12)
            completionMissingLabel.text = "Add: \(missingFields.joined(separator: ", "))"
        }
    }

    private func missingCareerIdentityFields(for profile: UserProfile) -> [String] {
        let values: [(String, String)] = [
            ("name", profile.name),
            ("email", profile.email),
            ("phone", profile.phone),
            ("location", profile.location),
            ("target role", profile.jobTitle),
            ("professional summary", profile.professionalSummary)
        ]
        return values.compactMap { name, value in
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? name : nil
        }
    }

    private func updateCVStudioUI(_ profile: UserProfile) {
        let sectionsReady = [
            !profile.skills.isEmpty,
            !profile.resolvedWorkExperiences.isEmpty,
            !profile.resolvedEducationEntries.isEmpty,
            !profile.resolvedQualificationEntries.isEmpty
        ]
        let completedSections = sectionsReady.filter { $0 }.count
        let percentage = Int((Double(completedSections) / Double(sectionsReady.count)) * 100)

        if completedSections == sectionsReady.count {
            cvStudioStatusLabel.text = "CV ready for review  |  References \(profile.references.isEmpty ? "optional" : "added")"
        } else {
            cvStudioStatusLabel.text = "\(completedSections) of \(sectionsReady.count) core sections ready"
        }

        cvStudioCardView.accessibilityValue = cvStudioStatusLabel.text
        updateCVProgress(percentage: percentage)
    }

    private func updateCVProgress(percentage: Int) {
        cvProgressWidthConstraint?.isActive = false
        let multiplier = max(0.001, min(1, CGFloat(percentage) / 100))
        let constraint = cvProgressFillView.widthAnchor.constraint(
            equalTo: cvProgressTrackView.widthAnchor,
            multiplier: multiplier
        )
        constraint.isActive = true
        cvProgressWidthConstraint = constraint
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

    @objc private func saveProfile() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        let profile = UserProfile(
            uid: user.uid,
            name: nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            email: emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? user.email ?? "",
            phone: phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            location: locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            profilePictureUrl: currentProfile.profilePictureUrl,
            profileImageData: currentProfile.profileImageData,
            cvUrl: currentProfile.cvUrl,
            cvFileName: currentProfile.cvFileName,
            professionalSummary: professionalSummaryText(),
            jobTitle: jobTitleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            skills: currentProfile.skills,
            qualifications: currentProfile.qualifications,
            experience: currentProfile.experience,
            education: currentProfile.education,
            workExperiences: currentProfile.workExperiences,
            educationEntries: currentProfile.educationEntries,
            qualificationEntries: currentProfile.qualificationEntries,
            references: currentProfile.references,
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

                let message = profile.isComplete
                    ? "Your career identity and CV are ready for applications."
                    : "Career identity saved. Continue in CV Studio to strengthen your application profile."
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

    @objc private func openAdminJobs() {
        let adminJobsViewController = AdminJobsViewController()
        adminJobsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(adminJobsViewController, animated: true)
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

    @objc private func openPrivacy() {
        let legalViewController = LegalViewController()
        legalViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(legalViewController, animated: true)
    }

    @objc private func createProfileTapped() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func homeTapped() {
        tabBarController?.selectedIndex = 0
    }

    @objc private func logout() {
        if let user = Auth.auth().currentUser, user.isAnonymous {
            user.delete { error in
                DispatchQueue.main.async {
                    if let error {
                        self.showAlert(
                            title: "Exit Guest Mode Failed",
                            message: FirebaseAuthenticationService.userMessage(for: error)
                        )
                    } else {
                        OnboardingState.reset()
                        AppRouter.showOnboarding()
                    }
                }
            }
            return
        }

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

    @objc private func deleteAccountTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            showRegistrationPrompt()
            return
        }

        guard let email = user.email, !email.isEmpty else {
            showAlert(
                title: "Account Deletion",
                message: "This account cannot be verified for deletion. Sign out, sign in again, and retry."
            )
            return
        }

        let alert = UIAlertController(
            title: "Delete Account Permanently?",
            message: "This removes your profile, saved jobs, applications, and sign-in account. This cannot be undone. Enter your password to confirm.",
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = "Password"
            $0.isSecureTextEntry = true
            $0.textContentType = .password
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self, weak alert] _ in
            let password = alert?.textFields?.first?.text ?? ""
            self?.deleteAccount(email: email, password: password, user: user)
        })
        present(alert, animated: true)
    }

    private func deleteAccount(email: String, password: String, user: User) {
        guard !password.isEmpty else {
            showAlert(title: "Password Needed", message: "Enter your password to delete the account.")
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        view.isUserInteractionEnabled = false

        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(
                        title: "Account Not Deleted",
                        message: FirebaseAuthenticationService.userMessage(for: error)
                    )
                }
                return
            }

            self.firestoreService.deleteUserData(userId: user.uid) { [weak self] error in
                guard let self else { return }

                if let error {
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(title: "Account Not Deleted", message: error.localizedDescription)
                    return
                }

                user.delete { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.view.isUserInteractionEnabled = true

                        if let error {
                            self.showAlert(
                                title: "Account Not Deleted",
                                message: FirebaseAuthenticationService.userMessage(for: error)
                            )
                            return
                        }

                        OnboardingState.reset()
                        AppRouter.showOnboarding()
                    }
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

        do {
            let avatarData = try ProfilePictureService.shared.makeFirestoreAvatarData(from: image)
            currentProfile.profileImageData = avatarData
            profileImageView.image = ProfilePictureService.shared.image(fromFirestoreData: avatarData)
            saveProfile()
        } catch {
            showAlert(title: "Photo Not Saved", message: error.localizedDescription)
        }
    }
}
