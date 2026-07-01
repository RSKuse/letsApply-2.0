//
//  Z83EditorViewController.swift
//  letsApply
//

import UIKit

final class Z83EditorViewController: UIViewController {

    var onZ83Ready: ((URL) -> Void)?

    private let job: Job
    private let userProfile: UserProfile
    private let profileStore = Z83ProfileStore()
    private let pdfService = Z83PDFService()
    private var z83Profile: Z83ApplicationProfile
    private var didRunDebugAutomation = false

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .interactive
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var headerCard = makeCard()
    private lazy var detailsCard = makeCard()
    private lazy var declarationsCard = makeCard()
    private lazy var signatureCard = makeCard()

    private lazy var dateOfBirthField = makeTextField(
        placeholder: "Date of birth (DD/MM/YYYY)",
        keyboardType: .numbersAndPunctuation
    )
    private lazy var identityNumberField = makeTextField(
        placeholder: "South African identity number",
        keyboardType: .numberPad
    )
    private lazy var passportNumberField = makeTextField(
        placeholder: "Passport number (if applicable)"
    )
    private lazy var nationalityField = makeTextField(
        placeholder: "Nationality if not South African"
    )
    private lazy var availabilityField = makeTextField(
        placeholder: "Availability or notice period"
    )
    private lazy var preferredLanguageField = makeTextField(
        placeholder: "Preferred correspondence language"
    )
    private lazy var privateSectorYearsField = makeTextField(
        placeholder: "Private-sector experience in years",
        keyboardType: .decimalPad
    )
    private lazy var publicSectorYearsField = makeTextField(
        placeholder: "Public-sector experience in years",
        keyboardType: .decimalPad
    )
    private lazy var registrationDateField = makeTextField(
        placeholder: "Professional registration date (optional)"
    )
    private lazy var registrationNumberField = makeTextField(
        placeholder: "Professional registration number (optional)"
    )

    private lazy var raceButton = makeSelectionButton(
        title: "Select race",
        options: ["African", "White", "Coloured", "Indian", "Other"]
    )
    private lazy var genderButton = makeSelectionButton(
        title: "Select gender",
        options: ["Female", "Male"]
    )
    private lazy var communicationButton = makeSelectionButton(
        title: "Preferred contact method",
        options: ["Email", "Telephone", "Post", "Fax"]
    )

    private lazy var disabilityRow = DeclarationRowView(
        title: "Do you have a disability?"
    )
    private lazy var citizenshipRow = DeclarationRowView(
        title: "Are you a South African citizen?"
    )
    private lazy var workPermitRow = DeclarationRowView(
        title: "Do you have a valid work permit if required?"
    )
    private lazy var convictionRow = DeclarationRowView(
        title: "Have you been convicted or found guilty of a criminal offence?",
        detailPlaceholder: "Provide conviction details if Yes"
    )
    private lazy var pendingCriminalRow = DeclarationRowView(
        title: "Do you have a pending criminal case?",
        detailPlaceholder: "Provide pending case details if Yes"
    )
    private lazy var dismissalRow = DeclarationRowView(
        title: "Have you been dismissed for misconduct from the Public Service?",
        detailPlaceholder: "Provide dismissal details if Yes"
    )
    private lazy var disciplinaryRow = DeclarationRowView(
        title: "Do you have a pending disciplinary case?",
        detailPlaceholder: "Provide disciplinary details if Yes"
    )
    private lazy var resignationRow = DeclarationRowView(
        title: "Have you resigned pending disciplinary proceedings?",
        detailPlaceholder: "Provide resignation details if Yes"
    )
    private lazy var illHealthRow = DeclarationRowView(
        title: "Were you discharged or retired from the Public Service on ill-health grounds?",
        detailPlaceholder: "Provide details if Yes"
    )
    private lazy var stateBusinessRow = DeclarationRowView(
        title: "Do you conduct business with the State?",
        detailPlaceholder: "Provide business details if Yes"
    )
    private lazy var relinquishRow = DeclarationRowView(
        title: "Will you relinquish those business interests if appointed?"
    )
    private lazy var publicServiceRestrictionRow = DeclarationRowView(
        title: "Is there a condition preventing your reappointment in the Public Service?",
        detailPlaceholder: "Provide the department and condition if Yes"
    )

    private lazy var signatureCanvas: SignatureCanvasView = {
        let view = SignatureCanvasView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var declarationSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = AppTheme.brand
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var reviewButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Review Completed Z83",
            systemImageName: "doc.text.magnifyingglass"
        )
        button.addTarget(self, action: #selector(reviewTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(job: Job, userProfile: UserProfile) {
        self.job = job
        self.userProfile = userProfile
        let stored = Z83ProfileStore().load(userId: userProfile.uid)
        self.z83Profile = Z83ApplicationProfile.make(for: userProfile, saved: stored)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Prepare Z83"
        view.backgroundColor = AppTheme.background
        setupUI()
        configure(with: z83Profile)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if signatureCanvas.signatureStrokes.isEmpty, !z83Profile.signatureStrokes.isEmpty {
            signatureCanvas.signatureStrokes = z83Profile.signatureStrokes
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        guard !didRunDebugAutomation,
              ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_Z83_PREVIEW"] == "1" else {
            return
        }
        didRunDebugAutomation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.reviewTapped()
        }
        #endif
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(reviewButton)
        scrollView.addSubview(contentStackView)

        setupHeaderCard()
        setupDetailsCard()
        setupDeclarationsCard()
        setupSignatureCard()

        [headerCard, detailsCard, declarationsCard, signatureCard].forEach {
            contentStackView.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: reviewButton.topAnchor, constant: -12),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            reviewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reviewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            reviewButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            reviewButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func setupHeaderCard() {
        let eyebrow = makeLabel(
            text: "GOVERNMENT APPLICATION",
            font: .systemFont(ofSize: 11, weight: .bold),
            color: AppTheme.brand
        )
        let title = makeLabel(
            text: job.title,
            font: .systemFont(ofSize: 21, weight: .bold),
            color: .label,
            lines: 0
        )
        let detail = makeLabel(
            text: "\(job.companyName)\nReference: \(job.application.referenceNumber.isEmpty ? "Not supplied" : job.application.referenceNumber)",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: AppTheme.secondaryText,
            lines: 0
        )
        let note = makeLabel(
            text: "Your CV Studio education, work history, and three references are inserted automatically. Sensitive Z83 answers stay securely on this device.",
            font: .systemFont(ofSize: 13, weight: .medium),
            color: AppTheme.secondaryText,
            lines: 0
        )
        let stack = cardStack([eyebrow, title, detail, note])
        pin(stack, to: headerCard)
    }

    private func setupDetailsCard() {
        let title = makeLabel(
            text: "Personal Details",
            font: .systemFont(ofSize: 18, weight: .bold),
            color: .label
        )
        let stack = cardStack([
            title,
            dateOfBirthField,
            identityNumberField,
            passportNumberField,
            raceButton,
            genderButton,
            nationalityField,
            availabilityField,
            preferredLanguageField,
            communicationButton,
            privateSectorYearsField,
            publicSectorYearsField,
            registrationDateField,
            registrationNumberField
        ])
        pin(stack, to: detailsCard)
    }

    private func setupDeclarationsCard() {
        let title = makeLabel(
            text: "Legal Declarations",
            font: .systemFont(ofSize: 18, weight: .bold),
            color: .label
        )
        let note = makeLabel(
            text: "Let’s Apply never guesses these answers. Complete them once, review them for every application, and change them whenever your circumstances change.",
            font: .systemFont(ofSize: 13, weight: .medium),
            color: AppTheme.secondaryText,
            lines: 0
        )
        let rows = [
            disabilityRow,
            citizenshipRow,
            workPermitRow,
            convictionRow,
            pendingCriminalRow,
            dismissalRow,
            disciplinaryRow,
            resignationRow,
            illHealthRow,
            stateBusinessRow,
            relinquishRow,
            publicServiceRestrictionRow
        ]
        let stack = cardStack([title, note] + rows)
        stack.setCustomSpacing(14, after: note)
        pin(stack, to: declarationsCard)
    }

    private func setupSignatureCard() {
        let title = makeLabel(
            text: "Signature and Declaration",
            font: .systemFont(ofSize: 18, weight: .bold),
            color: .label
        )
        let note = makeLabel(
            text: "Sign inside the box. The current application date is inserted when the PDF is generated.",
            font: .systemFont(ofSize: 13, weight: .medium),
            color: AppTheme.secondaryText,
            lines: 0
        )
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear Signature", for: .normal)
        clearButton.setTitleColor(AppTheme.brand, for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        clearButton.contentHorizontalAlignment = .trailing
        clearButton.addTarget(self, action: #selector(clearSignatureTapped), for: .touchUpInside)

        let declarationLabel = makeLabel(
            text: "I confirm that the information is complete and correct and I approve applying my signature to this Z83.",
            font: .systemFont(ofSize: 13, weight: .semibold),
            color: .label,
            lines: 0
        )
        let declarationRow = UIStackView(arrangedSubviews: [declarationLabel, declarationSwitch])
        declarationRow.axis = .horizontal
        declarationRow.alignment = .center
        declarationRow.spacing = 12

        let stack = cardStack([
            title,
            note,
            signatureCanvas,
            clearButton,
            declarationRow
        ])
        pin(stack, to: signatureCard)

        NSLayoutConstraint.activate([
            signatureCanvas.heightAnchor.constraint(equalToConstant: 150),
            declarationSwitch.widthAnchor.constraint(equalToConstant: 51)
        ])
    }

    private func configure(with profile: Z83ApplicationProfile) {
        dateOfBirthField.text = profile.dateOfBirth
        identityNumberField.text = profile.identityNumber
        passportNumberField.text = profile.passportNumber
        nationalityField.text = profile.nationality
        availabilityField.text = profile.availability
        preferredLanguageField.text = profile.preferredLanguage
        privateSectorYearsField.text = profile.privateSectorYears
        publicSectorYearsField.text = profile.publicSectorYears
        registrationDateField.text = profile.registrationDate
        registrationNumberField.text = profile.registrationNumber
        setSelectionButton(raceButton, title: profile.race, fallback: "Select race")
        setSelectionButton(genderButton, title: profile.gender, fallback: "Select gender")
        setSelectionButton(
            communicationButton,
            title: profile.communicationMethod,
            fallback: "Preferred contact method"
        )

        disabilityRow.configure(value: profile.hasDisability)
        citizenshipRow.configure(value: profile.isSouthAfricanCitizen)
        workPermitRow.configure(value: profile.hasValidWorkPermit)
        convictionRow.configure(
            value: profile.hasCriminalConviction,
            details: profile.criminalConvictionDetails
        )
        pendingCriminalRow.configure(
            value: profile.hasPendingCriminalCase,
            details: profile.pendingCriminalCaseDetails
        )
        dismissalRow.configure(
            value: profile.dismissedForPublicServiceMisconduct,
            details: profile.dismissalDetails
        )
        disciplinaryRow.configure(
            value: profile.hasPendingDisciplinaryCase,
            details: profile.disciplinaryCaseDetails
        )
        resignationRow.configure(
            value: profile.resignedPendingDisciplinaryProceedings,
            details: profile.resignationDetails
        )
        illHealthRow.configure(
            value: profile.dischargedForIllHealth,
            details: profile.illHealthDetails
        )
        stateBusinessRow.configure(
            value: profile.conductsBusinessWithState,
            details: profile.businessWithStateDetails
        )
        relinquishRow.configure(value: profile.willRelinquishBusinessInterests)
        publicServiceRestrictionRow.configure(
            value: profile.previousPublicServiceRestriction,
            details: profile.previousPublicServiceRestrictionDetails
        )
        signatureCanvas.signatureStrokes = profile.signatureStrokes
        declarationSwitch.isOn = profile.declarationAccepted
    }

    private func captureProfile() -> Z83ApplicationProfile {
        Z83ApplicationProfile(
            fullName: userProfile.name,
            dateOfBirth: dateOfBirthField.text ?? "",
            identityNumber: identityNumberField.text ?? "",
            passportNumber: passportNumberField.text ?? "",
            race: selectedValue(
                from: raceButton,
                excluding: ["Select race"]
            ),
            gender: selectedValue(
                from: genderButton,
                excluding: ["Select gender"]
            ),
            hasDisability: disabilityRow.value,
            isSouthAfricanCitizen: citizenshipRow.value,
            nationality: nationalityField.text ?? "",
            hasValidWorkPermit: workPermitRow.value,
            hasCriminalConviction: convictionRow.value,
            criminalConvictionDetails: convictionRow.details,
            hasPendingCriminalCase: pendingCriminalRow.value,
            pendingCriminalCaseDetails: pendingCriminalRow.details,
            dismissedForPublicServiceMisconduct: dismissalRow.value,
            dismissalDetails: dismissalRow.details,
            hasPendingDisciplinaryCase: disciplinaryRow.value,
            disciplinaryCaseDetails: disciplinaryRow.details,
            resignedPendingDisciplinaryProceedings: resignationRow.value,
            resignationDetails: resignationRow.details,
            dischargedForIllHealth: illHealthRow.value,
            illHealthDetails: illHealthRow.details,
            conductsBusinessWithState: stateBusinessRow.value,
            businessWithStateDetails: stateBusinessRow.details,
            willRelinquishBusinessInterests: relinquishRow.value,
            privateSectorYears: privateSectorYearsField.text ?? "",
            publicSectorYears: publicSectorYearsField.text ?? "",
            registrationDate: registrationDateField.text ?? "",
            registrationNumber: registrationNumberField.text ?? "",
            preferredLanguage: preferredLanguageField.text ?? "",
            communicationMethod: selectedValue(
                from: communicationButton,
                excluding: ["Preferred contact method"]
            ),
            availability: availabilityField.text ?? "",
            previousPublicServiceRestriction: publicServiceRestrictionRow.value,
            previousPublicServiceRestrictionDetails: publicServiceRestrictionRow.details,
            signatureStrokes: signatureCanvas.signatureStrokes,
            declarationAccepted: declarationSwitch.isOn
        )
    }

    @objc private func reviewTapped() {
        view.endEditing(true)
        let profile = captureProfile()
        guard profile.isComplete else {
            showAlert(
                title: "Z83 Needs Attention",
                message: "Complete: \(profile.missingRequiredFields.joined(separator: ", "))."
            )
            return
        }

        do {
            try profileStore.save(profile, userId: userProfile.uid)
            let url = try pdfService.generateZ83(
                profile: profile,
                userProfile: userProfile,
                job: job
            )
            z83Profile = profile
            let preview = Z83PreviewViewController(fileURL: url)
            preview.onUseForm = { [weak self] in
                self?.onZ83Ready?(url)
            }
            navigationController?.pushViewController(preview, animated: true)
        } catch {
            showAlert(title: "Z83 Could Not Be Prepared", message: error.localizedDescription)
        }
    }

    @objc private func clearSignatureTapped() {
        signatureCanvas.clear()
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func cardStack(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func pin(_ stack: UIStackView, to card: UIView) {
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func makeTextField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.keyboardType = keyboardType
        field.autocapitalizationType = .sentences
        field.backgroundColor = AppTheme.background
        field.layer.cornerRadius = AppTheme.cardRadius
        field.layer.borderColor = AppTheme.border.cgColor
        field.layer.borderWidth = 1
        field.font = .systemFont(ofSize: 15, weight: .medium)
        field.setLeftPaddingPoints(12)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return field
    }

    private func makeSelectionButton(title: String, options: [String]) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = title
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .small
        button.configuration = configuration
        button.contentHorizontalAlignment = .fill
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(children: options.map { option in
            UIAction(title: option) { [weak button] _ in
                button?.configuration?.title = option
            }
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func setSelectionButton(_ button: UIButton, title: String, fallback: String) {
        button.configuration?.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? fallback
            : title
    }

    private func selectedValue(from button: UIButton, excluding placeholders: [String]) -> String {
        let title = button.configuration?.title ?? ""
        return placeholders.contains(title) ? "" : title
    }

    private func makeLabel(
        text: String,
        font: UIFont,
        color: UIColor,
        lines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private final class DeclarationRowView: UIView {

    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Yes", "No"])
    private let detailField = UITextField()

    var value: Z83YesNo? {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return .yes
        case 1:
            return .no
        default:
            return nil
        }
    }

    var details: String {
        detailField.text ?? ""
    }

    init(title: String, detailPlaceholder: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = AppTheme.background
        layer.cornerRadius = AppTheme.cardRadius
        layer.borderColor = AppTheme.border.cgColor
        layer.borderWidth = 1
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        segmentedControl.selectedSegmentTintColor = AppTheme.brand
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        segmentedControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        detailField.placeholder = detailPlaceholder
        detailField.font = .systemFont(ofSize: 14, weight: .medium)
        detailField.backgroundColor = AppTheme.surface
        detailField.layer.cornerRadius = AppTheme.cardRadius
        detailField.layer.borderColor = AppTheme.border.cgColor
        detailField.layer.borderWidth = 1
        detailField.setLeftPaddingPoints(10)
        detailField.isHidden = detailPlaceholder == nil

        let stack = UIStackView(arrangedSubviews: [titleLabel, segmentedControl, detailField])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),
            detailField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: Z83YesNo?, details: String = "") {
        switch value {
        case .yes:
            segmentedControl.selectedSegmentIndex = 0
        case .no:
            segmentedControl.selectedSegmentIndex = 1
        case nil:
            segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        detailField.text = details
        updateDetailVisibility()
    }

    @objc private func selectionChanged() {
        updateDetailVisibility()
    }

    private func updateDetailVisibility() {
        guard detailField.placeholder != nil else { return }
        detailField.isHidden = value != .yes
        if value != .yes {
            detailField.text = ""
        }
    }
}
