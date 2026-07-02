//
//  AdminJobEditorViewController.swift
//  letsApply
//

import UIKit

class AdminJobEditorViewController: UIViewController {

    var onSaved: (() -> Void)?

    private let existingJob: Job?
    private let isDebugMode: Bool
    private let firestoreService = FirestoreService()
    private var selectedApplicationMethod: JobApplicationMethod = .internalApply
    private var selectedSourceType: JobSourceType = .manual
    private var isSaving = false

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            statusCardView,
            basicsCardView,
            contentCardView,
            salaryCardView,
            applicationCardView,
            sourceCardView,
            actionStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var titleTextField = makeTextField(placeholder: "e.g. Risk Analyst")
    private lazy var companyTextField = makeTextField(placeholder: "Employer name")
    private lazy var companyLogoURLTextField = makeTextField(
        placeholder: "https://company.com/logo.png",
        keyboardType: .URL
    )
    private lazy var categoryTextField = makeTextField(placeholder: "e.g. Finance")
    private lazy var jobTypeTextField = makeTextField(placeholder: "e.g. Permanent")
    private lazy var cityTextField = makeTextField(placeholder: "City")
    private lazy var regionTextField = makeTextField(placeholder: "Province or region")
    private lazy var countryTextField = makeTextField(placeholder: "Country")
    private lazy var remoteSwitch = UISwitch()

    private lazy var descriptionTextView = makeTextView()
    private lazy var responsibilitiesTextView = makeTextView()
    private lazy var requirementsTextView = makeTextView()
    private lazy var qualificationsTextView = makeTextView()
    private lazy var benefitsTextView = makeTextView(height: 90)

    private lazy var minimumSalaryTextField = makeTextField(
        placeholder: "Minimum",
        keyboardType: .numberPad
    )
    private lazy var maximumSalaryTextField = makeTextField(
        placeholder: "Maximum",
        keyboardType: .numberPad
    )
    private lazy var currencyTextField = makeTextField(placeholder: "ZAR")
    private lazy var minimumYearsTextField = makeTextField(
        placeholder: "Minimum years",
        keyboardType: .numberPad
    )
    private lazy var preferredYearsTextField = makeTextField(
        placeholder: "Preferred years",
        keyboardType: .numberPad
    )
    private lazy var experienceDetailsTextField = makeTextField(
        placeholder: "Experience notes"
    )

    private lazy var payPeriodControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Annual", "Monthly", "Weekly", "Hourly"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = AppTheme.brand
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private lazy var applicationMethodButton: UIButton = {
        let button = makeMenuButton()
        button.accessibilityLabel = "Application method"
        return button
    }()

    private lazy var applicationMethodDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private lazy var applicationEmailTextField = makeTextField(
        placeholder: "Employer application email",
        keyboardType: .emailAddress
    )
    private lazy var applicationURLTextField = makeTextField(
        placeholder: "https://company.com/careers",
        keyboardType: .URL
    )
    private lazy var contactPhoneTextField = makeTextField(
        placeholder: "Contact phone",
        keyboardType: .phonePad
    )
    private lazy var formNameTextField = makeTextField(
        placeholder: "Form name, if required"
    )
    private lazy var referenceNumberTextField = makeTextField(
        placeholder: "Vacancy reference number"
    )
    private lazy var applicationInstructionsTextView = makeTextView(height: 100)
    private lazy var requiredFormsTextView = makeTextView(height: 82)
    private lazy var requiredDocumentsTextView = makeTextView(height: 82)
    private lazy var postalAddressTextView = makeTextView(height: 82)
    private lazy var handDeliveryAddressTextView = makeTextView(height: 82)

    private lazy var requiresCVSwitch = configuredSwitch(isOn: true)
    private lazy var requiresCoverLetterSwitch = configuredSwitch(isOn: true)
    private lazy var requiresZ83Switch = configuredSwitch(isOn: false)
    private lazy var requiresCertifiedDocumentsSwitch = configuredSwitch(isOn: false)
    private lazy var requiresDriversLicenseSwitch = configuredSwitch(isOn: false)

    private lazy var closingDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Calendar.current.startOfDay(for: Date())
        return picker
    }()

    private lazy var sourceNameTextField = makeTextField(
        placeholder: "e.g. Employer careers page"
    )
    private lazy var sourceURLTextField = makeTextField(
        placeholder: "Original vacancy URL",
        keyboardType: .URL
    )
    private lazy var sourceJobIDTextField = makeTextField(
        placeholder: "External vacancy ID"
    )
    private lazy var sourceTypeButton: UIButton = {
        let button = makeMenuButton()
        button.accessibilityLabel = "Job source type"
        return button
    }()
    private lazy var verifiedSwitch = configuredSwitch(isOn: false)
    private lazy var featuredSwitch = configuredSwitch(isOn: false)
    private lazy var promotedSwitch = configuredSwitch(isOn: false)

    private lazy var statusCardView: UIView = {
        let status = existingJob?.resolvedPublicationStatus ?? .draft
        let content = makeVerticalStack([
            makeStatusRow(status: status),
            makeDateRow(title: "Closing Date", datePicker: closingDatePicker)
        ], spacing: 14)
        return makeSectionCard(
            title: "Publishing Status",
            subtitle: "Closing dates automatically remove expired vacancies from candidate screens.",
            content: content
        )
    }()

    private lazy var basicsCardView: UIView = {
        let content = makeVerticalStack([
            makeFieldGroup(title: "Job Title", field: titleTextField),
            makeFieldGroup(title: "Company", field: companyTextField),
            makeFieldGroup(
                title: "Company Logo URL",
                subtitle: "Optional HTTPS image supplied by the employer or source",
                field: companyLogoURLTextField
            ),
            makeFieldGroup(title: "Category", field: categoryTextField),
            makeFieldGroup(title: "Job Type", field: jobTypeTextField),
            makeFieldGroup(title: "City", field: cityTextField),
            makeFieldGroup(title: "Province / Region", field: regionTextField),
            makeFieldGroup(title: "Country", field: countryTextField),
            makeSwitchRow(title: "Remote friendly", toggle: remoteSwitch)
        ])
        return makeSectionCard(
            title: "Vacancy Basics",
            subtitle: "The information candidates scan first.",
            content: content
        )
    }()

    private lazy var contentCardView: UIView = {
        let content = makeVerticalStack([
            makeFieldGroup(title: "Job Description", field: descriptionTextView),
            makeFieldGroup(
                title: "Responsibilities",
                subtitle: "One responsibility per line",
                field: responsibilitiesTextView
            ),
            makeFieldGroup(
                title: "Requirements",
                subtitle: "One requirement per line",
                field: requirementsTextView
            ),
            makeFieldGroup(
                title: "Qualifications",
                subtitle: "One qualification per line",
                field: qualificationsTextView
            ),
            makeFieldGroup(
                title: "Benefits",
                subtitle: "One benefit per line",
                field: benefitsTextView
            )
        ])
        return makeSectionCard(
            title: "Role Content",
            subtitle: "Use precise language that can support matching and document generation.",
            content: content
        )
    }()

    private lazy var salaryCardView: UIView = {
        let salaryRow = makeHorizontalStack([
            makeFieldGroup(title: "Minimum", field: minimumSalaryTextField),
            makeFieldGroup(title: "Maximum", field: maximumSalaryTextField)
        ])
        let experienceRow = makeHorizontalStack([
            makeFieldGroup(title: "Min Years", field: minimumYearsTextField),
            makeFieldGroup(title: "Preferred", field: preferredYearsTextField)
        ])
        let content = makeVerticalStack([
            salaryRow,
            makeFieldGroup(title: "Currency", field: currencyTextField),
            makeFieldGroup(title: "Pay Period", field: payPeriodControl),
            experienceRow,
            makeFieldGroup(title: "Experience Detail", field: experienceDetailsTextField)
        ])
        return makeSectionCard(
            title: "Compensation & Experience",
            subtitle: "Salary is formatted automatically for candidates.",
            content: content
        )
    }()

    private lazy var applicationCardView: UIView = {
        let content = makeVerticalStack([
            makeFieldGroup(title: "Application Method", field: applicationMethodButton),
            applicationMethodDetailLabel,
            makeFieldGroup(title: "Application Email", field: applicationEmailTextField),
            makeFieldGroup(title: "Application Website", field: applicationURLTextField),
            makeFieldGroup(title: "Contact Phone", field: contactPhoneTextField),
            makeFieldGroup(title: "Required Form", field: formNameTextField),
            makeFieldGroup(title: "Reference Number", field: referenceNumberTextField),
            makeFieldGroup(title: "Application Instructions", field: applicationInstructionsTextView),
            makeFieldGroup(
                title: "Required Forms",
                subtitle: "One form per line",
                field: requiredFormsTextView
            ),
            makeFieldGroup(
                title: "Required Documents",
                subtitle: "One document per line",
                field: requiredDocumentsTextView
            ),
            makeFieldGroup(title: "Postal Address", field: postalAddressTextView),
            makeFieldGroup(title: "Hand Delivery Address", field: handDeliveryAddressTextView),
            makeSwitchRow(title: "CV required", toggle: requiresCVSwitch),
            makeSwitchRow(title: "Cover letter required", toggle: requiresCoverLetterSwitch),
            makeSwitchRow(title: "Z83 required", toggle: requiresZ83Switch),
            makeSwitchRow(
                title: "Certified documents required",
                toggle: requiresCertifiedDocumentsSwitch
            ),
            makeSwitchRow(
                title: "Driver’s licence required",
                toggle: requiresDriversLicenseSwitch
            )
        ])
        return makeSectionCard(
            title: "Application Route",
            subtitle: "Submit Application uses this route to choose the correct candidate flow.",
            content: content
        )
    }()

    private lazy var sourceCardView: UIView = {
        let content = makeVerticalStack([
            makeFieldGroup(title: "Source Name", field: sourceNameTextField),
            makeFieldGroup(title: "Original Source URL", field: sourceURLTextField),
            makeFieldGroup(title: "Source Vacancy ID", field: sourceJobIDTextField),
            makeFieldGroup(title: "Source Type", field: sourceTypeButton),
            makeSwitchRow(title: "Source verified", toggle: verifiedSwitch),
            makeSwitchRow(title: "Featured vacancy", toggle: featuredSwitch),
            makeSwitchRow(title: "Promoted vacancy", toggle: promotedSwitch)
        ])
        return makeSectionCard(
            title: "Trust & Visibility",
            subtitle: "Every real vacancy should have a traceable source.",
            content: content
        )
    }()

    private lazy var previewButton: UIButton = {
        let button = makeSecondaryButton(
            title: "Preview Vacancy",
            systemImageName: "eye"
        )
        button.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)
        return button
    }()

    private lazy var draftButton: UIButton = {
        let button = makeSecondaryButton(
            title: "Save Draft",
            systemImageName: "square.and.arrow.down"
        )
        button.addTarget(self, action: #selector(saveDraftTapped), for: .touchUpInside)
        return button
    }()

    private lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: existingJob?.resolvedPublicationStatus == .published
                ? "Update Published Vacancy"
                : "Publish Vacancy",
            systemImageName: "paperplane.fill"
        )
        button.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var actionStackView: UIStackView = {
        let stackView = makeVerticalStack([
            previewButton,
            draftButton,
            publishButton
        ], spacing: 10)
        [previewButton, draftButton, publishButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: 52).isActive = true
        }
        return stackView
    }()

    init(job: Job? = nil, isDebugMode: Bool = false) {
        self.existingJob = job
        self.isDebugMode = isDebugMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = existingJob == nil ? "Create Vacancy" : "Edit Vacancy"
        view.backgroundColor = AppTheme.background
        setupUI()
        configureMenus()
        populateExistingJob()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        guard ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_ADMIN_SCROLL"] == "actions" else {
            return
        }
        view.layoutIfNeeded()
        let maximumOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: maximumOffset), animated: false)
        #endif
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 18),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func configureMenus() {
        applicationMethodButton.menu = UIMenu(
            title: "Application Method",
            children: JobApplicationMethod.allCases.map { method in
                UIAction(
                    title: method.editorTitle,
                    state: method == selectedApplicationMethod ? .on : .off
                ) { [weak self] _ in
                    self?.selectedApplicationMethod = method
                    self?.configureMenus()
                }
            }
        )
        applicationMethodButton.configuration?.title = selectedApplicationMethod.editorTitle
        applicationMethodDetailLabel.text = selectedApplicationMethod.editorDetail

        sourceTypeButton.menu = UIMenu(
            title: "Source Type",
            children: JobSourceType.allCases.map { sourceType in
                UIAction(
                    title: sourceType.title,
                    state: sourceType == selectedSourceType ? .on : .off
                ) { [weak self] _ in
                    self?.selectedSourceType = sourceType
                    self?.configureMenus()
                }
            }
        )
        sourceTypeButton.configuration?.title = selectedSourceType.title
    }

    private func populateExistingJob() {
        countryTextField.text = "South Africa"
        currencyTextField.text = "ZAR"
        sourceNameTextField.text = "Let’s Apply Editorial"
        closingDatePicker.date = Calendar.current.date(
            byAdding: .day,
            value: 30,
            to: Date()
        ) ?? Date()

        guard let job = existingJob else {
            if isDebugMode {
                populateDebugValues()
            }
            configureMenus()
            return
        }

        titleTextField.text = job.title
        companyTextField.text = job.companyName
        companyLogoURLTextField.text = job.companyLogoURL
        categoryTextField.text = job.jobCategory
        jobTypeTextField.text = job.jobType
        cityTextField.text = job.location.city
        regionTextField.text = job.location.region
        countryTextField.text = job.location.country
        remoteSwitch.isOn = job.remote
        descriptionTextView.text = job.description
        responsibilitiesTextView.text = job.responsibilities.joined(separator: "\n")
        requirementsTextView.text = job.requirements.joined(separator: "\n")
        qualificationsTextView.text = job.qualifications.joined(separator: "\n")
        benefitsTextView.text = job.compensation.benefits.joined(separator: "\n")
        minimumSalaryTextField.text = numberText(job.compensation.salaryRange.min)
        maximumSalaryTextField.text = numberText(job.compensation.salaryRange.max)
        currencyTextField.text = job.compensation.salaryRange.currency
        payPeriodControl.selectedSegmentIndex = payPeriodIndex(
            job.compensation.salaryRange.period
        )
        minimumYearsTextField.text = "\(job.experience.minYears)"
        preferredYearsTextField.text = "\(job.experience.preferredYears)"
        experienceDetailsTextField.text = job.experience.details
        selectedApplicationMethod = job.applicationMethod
        applicationEmailTextField.text = job.application.applicationEmail
        applicationURLTextField.text = job.application.applicationUrl
        contactPhoneTextField.text = job.application.contactPhone
        formNameTextField.text = job.application.formName
        referenceNumberTextField.text = job.application.referenceNumber
        applicationInstructionsTextView.text = job.application.applicationInstructions
        requiredFormsTextView.text = job.application.requiredForms.joined(separator: "\n")
        requiredDocumentsTextView.text = job.application.requiredDocuments.joined(separator: "\n")
        postalAddressTextView.text = job.application.postalAddress
        handDeliveryAddressTextView.text = job.application.handDeliveryAddress
        requiresCVSwitch.isOn = job.application.requiresCV
        requiresCoverLetterSwitch.isOn = job.application.requiresCoverLetter
        requiresZ83Switch.isOn = job.application.requiresZ83
        requiresCertifiedDocumentsSwitch.isOn = job.application.requiresCertifiedDocuments
        requiresDriversLicenseSwitch.isOn = job.application.requiresDriversLicense
        sourceNameTextField.text = job.sourceName
        sourceURLTextField.text = job.sourceUrl
        sourceJobIDTextField.text = job.sourceJobId
        selectedSourceType = JobSourceType(rawValue: job.sourceType) ?? .manual
        verifiedSwitch.isOn = job.verified
        featuredSwitch.isOn = job.visibility.featured
        promotedSwitch.isOn = job.visibility.promoted

        if let date = parseDate(job.closingDate) {
            closingDatePicker.date = date
        }
        configureMenus()
    }

    private func populateDebugValues() {
        titleTextField.text = "Risk Analyst"
        companyTextField.text = "Ubuntu Financial Services"
        categoryTextField.text = "Risk and Compliance"
        jobTypeTextField.text = "Permanent"
        cityTextField.text = "Johannesburg"
        regionTextField.text = "Gauteng"
        countryTextField.text = "South Africa"
        descriptionTextView.text = "Analyse operational risk, strengthen controls, and provide evidence-based recommendations to business leaders."
        responsibilitiesTextView.text = "Review risk indicators\nPrepare clear management reports\nCoordinate control-improvement actions"
        requirementsTextView.text = "Risk analysis\nReport writing\nStakeholder communication"
        qualificationsTextView.text = "Relevant bachelor’s degree"
        minimumSalaryTextField.text = "420000"
        maximumSalaryTextField.text = "560000"
        minimumYearsTextField.text = "3"
        preferredYearsTextField.text = "5"
        experienceDetailsTextField.text = "Financial services experience is advantageous"
        selectedApplicationMethod = .email
        applicationEmailTextField.text = "careers@example.co.za"
        sourceNameTextField.text = "Employer careers page"
        sourceURLTextField.text = "https://example.co.za/careers/risk-analyst"
        selectedSourceType = .companyWebsite
        verifiedSwitch.isOn = true
    }

    @objc private func previewTapped() {
        guard let job = makeJob(status: .draft, validateForPublishing: false) else {
            return
        }

        let preview = JobDetailsViewController(job: job, isPreviewMode: true)
        preview.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(preview, animated: true)
    }

    @objc private func saveDraftTapped() {
        save(status: .draft)
    }

    @objc private func publishTapped() {
        save(status: .published)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func save(status: JobPublicationStatus) {
        guard !isSaving else { return }
        guard let job = makeJob(
            status: status,
            validateForPublishing: status == .published
        ) else {
            return
        }

        if isDebugMode {
            showSavedAlert(status: status)
            return
        }

        setSaving(true)
        firestoreService.saveAdminJob(job) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setSaving(false)

                if let error {
                    self.showAlert(
                        title: "Vacancy Not Saved",
                        message: error.localizedDescription
                    )
                } else {
                    self.showSavedAlert(status: status)
                }
            }
        }
    }

    private func showSavedAlert(status: JobPublicationStatus) {
        let isPublished = status == .published
        let alert = UIAlertController(
            title: isPublished ? "Vacancy Published" : "Draft Saved",
            message: isPublished
                ? "The vacancy is now available to candidates until its closing date."
                : "The vacancy remains hidden from candidates.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.onSaved?()
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func makeJob(
        status: JobPublicationStatus,
        validateForPublishing: Bool
    ) -> Job? {
        let title = clean(titleTextField.text)
        let company = clean(companyTextField.text)
        guard !title.isEmpty, !company.isEmpty else {
            showAlert(
                title: "Add Vacancy Basics",
                message: "Job title and company are required, even for a draft."
            )
            return nil
        }

        if validateForPublishing, let validationMessage = publishingValidationMessage() {
            showAlert(title: "Vacancy Not Ready", message: validationMessage)
            return nil
        }

        let closingDate = Self.storageDateFormatter.string(from: closingDatePicker.date)
        let deadline = Self.displayDateFormatter.string(from: closingDatePicker.date)
        let postingDate = existingJob?.postingDate.isEmpty == false
            ? existingJob?.postingDate ?? Self.storageDateFormatter.string(from: Date())
            : Self.storageDateFormatter.string(from: Date())

        return Job(
            id: existingJob?.id,
            title: title,
            companyName: company,
            companyImageName: existingJob?.companyImageName,
            companyLogoURL: clean(companyLogoURLTextField.text),
            location: Location(
                city: clean(cityTextField.text),
                region: clean(regionTextField.text),
                country: clean(countryTextField.text)
            ),
            jobType: clean(jobTypeTextField.text),
            remote: remoteSwitch.isOn,
            description: clean(descriptionTextView.text),
            qualifications: lines(from: qualificationsTextView.text),
            responsibilities: lines(from: responsibilitiesTextView.text),
            requirements: lines(from: requirementsTextView.text),
            experience: Experience(
                minYears: integer(from: minimumYearsTextField.text),
                preferredYears: integer(from: preferredYearsTextField.text),
                details: clean(experienceDetailsTextField.text)
            ),
            compensation: Compensation(
                salaryRange: SalaryRange(
                    min: integer(from: minimumSalaryTextField.text),
                    max: integer(from: maximumSalaryTextField.text),
                    currency: clean(currencyTextField.text),
                    period: selectedPayPeriod.rawValue
                ),
                benefits: lines(from: benefitsTextView.text)
            ),
            application: JobApplicationInfo(
                deadline: deadline,
                applicationUrl: clean(applicationURLTextField.text),
                applicationEmail: clean(applicationEmailTextField.text),
                contactPhone: clean(contactPhoneTextField.text),
                method: selectedApplicationMethod.rawValue,
                formName: clean(formNameTextField.text),
                requiredForms: lines(from: requiredFormsTextView.text),
                requiredDocuments: lines(from: requiredDocumentsTextView.text),
                applicationInstructions: clean(applicationInstructionsTextView.text),
                requiresCoverLetter: requiresCoverLetterSwitch.isOn,
                requiresCV: requiresCVSwitch.isOn,
                requiresZ83: requiresZ83Switch.isOn,
                requiresCertifiedDocuments: requiresCertifiedDocumentsSwitch.isOn,
                referenceNumber: clean(referenceNumberTextField.text),
                postalAddress: clean(postalAddressTextView.text),
                handDeliveryAddress: clean(handDeliveryAddressTextView.text),
                requiresDriversLicense: requiresDriversLicenseSwitch.isOn
            ),
            jobCategory: clean(categoryTextField.text),
            postingDate: postingDate,
            visibility: Visibility(
                featured: featuredSwitch.isOn,
                promoted: promotedSwitch.isOn
            ),
            promoted: promotedSwitch.isOn ? ["Promoted"] : nil,
            sourceName: clean(sourceNameTextField.text),
            sourceUrl: clean(sourceURLTextField.text),
            sourceJobId: clean(sourceJobIDTextField.text),
            sourceType: selectedSourceType.rawValue,
            dateImported: existingJob?.dateImported ?? Self.storageDateFormatter.string(from: Date()),
            verified: verifiedSwitch.isOn,
            closingDate: closingDate,
            publicationStatus: status.rawValue
        )
    }

    private func publishingValidationMessage() -> String? {
        let requiredValues: [(String, String)] = [
            ("Category", clean(categoryTextField.text)),
            ("Job type", clean(jobTypeTextField.text)),
            ("City", clean(cityTextField.text)),
            ("Country", clean(countryTextField.text)),
            ("Job description", clean(descriptionTextView.text)),
            ("Source name", clean(sourceNameTextField.text))
        ]
        let missingFields = requiredValues
            .filter { $0.1.isEmpty }
            .map(\.0)
        if !missingFields.isEmpty {
            return "Complete: \(missingFields.joined(separator: ", "))."
        }

        if lines(from: responsibilitiesTextView.text).isEmpty {
            return "Add at least one responsibility."
        }

        if lines(from: requirementsTextView.text).isEmpty {
            return "Add at least one requirement."
        }

        if Calendar.current.startOfDay(for: closingDatePicker.date)
            < Calendar.current.startOfDay(for: Date()) {
            return "Choose a closing date that has not passed."
        }

        let minimumSalary = integer(from: minimumSalaryTextField.text)
        let maximumSalary = integer(from: maximumSalaryTextField.text)
        if minimumSalary > 0, maximumSalary > 0, maximumSalary < minimumSalary {
            return "Maximum salary cannot be lower than minimum salary."
        }

        switch selectedApplicationMethod {
        case .email, .governmentEmail:
            if !isValidEmail(clean(applicationEmailTextField.text)) {
                return "Add a valid application email address for this route."
            }
        case .externalWebsite, .governmentWebsite:
            if !isValidWebURL(clean(applicationURLTextField.text)) {
                return "Add a valid employer application website."
            }
        case .governmentManual, .pdfCircular, .manualInstruction:
            if clean(applicationInstructionsTextView.text).isEmpty {
                return "Add clear manual application instructions."
            }
        case .internalApply:
            break
        }

        let sourceURL = clean(sourceURLTextField.text)
        if !sourceURL.isEmpty, !isValidWebURL(sourceURL) {
            return "The original source URL must begin with http:// or https://."
        }

        let companyLogoURL = clean(companyLogoURLTextField.text)
        if !companyLogoURL.isEmpty,
           (!isValidWebURL(companyLogoURL)
            || !companyLogoURL.lowercased().hasPrefix("https://")) {
            return "The company logo must use a valid https:// image URL."
        }

        return nil
    }

    private var selectedPayPeriod: SalaryPayPeriod {
        switch payPeriodControl.selectedSegmentIndex {
        case 1:
            return .month
        case 2:
            return .week
        case 3:
            return .hour
        default:
            return .annum
        }
    }

    private func payPeriodIndex(_ value: String?) -> Int {
        switch value?.lowercased() {
        case SalaryPayPeriod.month.rawValue:
            return 1
        case SalaryPayPeriod.week.rawValue:
            return 2
        case SalaryPayPeriod.hour.rawValue:
            return 3
        default:
            return 0
        }
    }

    private func setSaving(_ saving: Bool) {
        isSaving = saving
        [previewButton, draftButton, publishButton].forEach {
            $0.isEnabled = !saving
        }
        publishButton.configuration?.title = saving ? "Saving..." : (
            existingJob?.resolvedPublicationStatus == .published
                ? "Update Published Vacancy"
                : "Publish Vacancy"
        )
    }

    private func numberText(_ value: Int) -> String {
        value > 0 ? "\(value)" : ""
    }

    private func clean(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func lines(from value: String?) -> [String] {
        clean(value)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func integer(from value: String?) -> Int {
        let digits = clean(value).filter(\.isNumber)
        return Int(digits) ?? 0
    }

    private func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.split(separator: "@").last?.contains(".") == true
    }

    private func isValidWebURL(_ value: String) -> Bool {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    private func parseDate(_ value: String) -> Date? {
        Self.storageDateFormatter.date(from: value)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension AdminJobEditorViewController {

    static var storageDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    static var displayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }

    func makeSectionCard(title: String, subtitle: String, content: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, content])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let cardView = UIView()
        cardView.backgroundColor = AppTheme.surface
        cardView.layer.cornerRadius = AppTheme.cardRadius
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppTheme.border.cgColor
        cardView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
        return cardView
    }

    func makeFieldGroup(
        title: String,
        subtitle: String? = nil,
        field: UIView
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 6

        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            subtitleLabel.textColor = AppTheme.secondaryText
            stackView.addArrangedSubview(subtitleLabel)
        }

        stackView.addArrangedSubview(field)
        return stackView
    }

    func makeVerticalStack(_ views: [UIView], spacing: CGFloat = 14) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = spacing
        return stackView
    }

    func makeHorizontalStack(_ views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }

    func makeTextField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.keyboardType = keyboardType
        field.autocapitalizationType = keyboardType == .emailAddress || keyboardType == .URL
            ? .none
            : .sentences
        field.autocorrectionType = keyboardType == .emailAddress || keyboardType == .URL
            ? .no
            : .default
        field.backgroundColor = AppTheme.background
        field.layer.cornerRadius = AppTheme.cardRadius
        field.layer.borderWidth = 1
        field.layer.borderColor = AppTheme.border.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return field
    }

    func makeTextView(height: CGFloat = 120) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.background
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderWidth = 1
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.heightAnchor.constraint(equalToConstant: height).isActive = true
        return textView
    }

    func makeMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = AppTheme.mutedSurface
        configuration.baseForegroundColor = AppTheme.brand
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.showsMenuAsPrimaryAction = true
        button.contentHorizontalAlignment = .fill
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }

    func makeSwitchRow(title: String, toggle: UISwitch) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [label, toggle])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return stackView
    }

    func makeStatusRow(status: JobPublicationStatus) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = existingJob == nil ? "New vacancy" : status.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = status == .published ? AppTheme.brand : .label

        let detailLabel = UILabel()
        detailLabel.text = existingJob == nil
            ? "Starts as a draft until you publish it."
            : "Current status"
        detailLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        detailLabel.textColor = AppTheme.secondaryText

        return makeVerticalStack([titleLabel, detailLabel], spacing: 4)
    }

    func makeDateRow(title: String, datePicker: UIDatePicker) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [label, datePicker])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }

    func configuredSwitch(isOn: Bool) -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = AppTheme.brand
        return toggle
    }

    func makeSecondaryButton(title: String, systemImageName: String) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: systemImageName)
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = AppTheme.mutedSurface
        configuration.baseForegroundColor = AppTheme.brand
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
