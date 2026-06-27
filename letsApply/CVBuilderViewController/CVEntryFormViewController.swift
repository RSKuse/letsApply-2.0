//
//  CVEntryFormViewController.swift
//  letsApply
//

import UIKit

final class CVEntryFormViewController: UIViewController {

    var onSave: ((CVEditorEntry) -> Void)?

    private let section: CVSectionKind
    private let existingEntry: CVEditorEntry?
    private var textFields: [String: UITextField] = [:]

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var notesTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.surface
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderWidth = 1
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Save Entry",
            systemImageName: "checkmark"
        )
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(section: CVSectionKind, entry: CVEditorEntry?) {
        self.section = section
        self.existingEntry = entry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = existingEntry == nil ? "Add \(section.title)" : "Edit \(section.title)"
        setupUI()
        configureFields()
        populateExistingEntry()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            saveButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func configureFields() {
        switch section {
        case .experience:
            addTextField(key: "jobTitle", label: "Job title", placeholder: "Software Developer")
            addTextField(key: "company", label: "Company", placeholder: "Company name")
            addTextField(key: "location", label: "Location", placeholder: "City, province or remote")
            addDateFields(startLabel: "Start date", endLabel: "End date")
            addNotesField(
                label: "Key achievements and responsibilities",
                helpText: "Use one clear achievement per line. Start with strong action words."
            )
        case .education:
            addTextField(key: "qualification", label: "Qualification", placeholder: "Bachelor of Commerce")
            addTextField(key: "institution", label: "Institution", placeholder: "University or college")
            addTextField(key: "fieldOfStudy", label: "Field of study", placeholder: "Public Management")
            addDateFields(startLabel: "Start year", endLabel: "End year")
            addNotesField(
                label: "Additional details",
                helpText: "Optional: distinctions, research topic, or relevant coursework."
            )
        case .qualifications:
            addTextField(
                key: "title",
                label: "Certificate or qualification",
                placeholder: "AWS Cloud Practitioner"
            )
            addTextField(key: "issuer", label: "Issuer", placeholder: "Amazon Web Services")
            addTextField(key: "year", label: "Year", placeholder: "2026")
        case .references:
            addTextField(key: "name", label: "Full name", placeholder: "Dr Amina Ndlovu")
            addTextField(key: "jobTitle", label: "Job title", placeholder: "Programme Director")
            addTextField(key: "company", label: "Organisation", placeholder: "Organisation name")
            addTextField(
                key: "relationship",
                label: "Professional relationship",
                placeholder: "Former manager"
            )
            addTextField(
                key: "email",
                label: "Email",
                placeholder: "reference@example.com",
                keyboardType: .emailAddress
            )
            addTextField(
                key: "phone",
                label: "Phone",
                placeholder: "+27 00 000 0000",
                keyboardType: .phonePad
            )
        }
    }

    private func addTextField(
        key: String,
        label: String,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) {
        let fieldLabel = makeLabel(text: label, weight: .bold)
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = AppTheme.surface
        textField.layer.cornerRadius = AppTheme.cardRadius
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppTheme.border.cgColor
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = keyboardType == .emailAddress ? .none : .sentences
        textField.autocorrectionType = keyboardType == .emailAddress ? .no : .default
        textField.setLeftPadding(14)
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let fieldStack = UIStackView(arrangedSubviews: [fieldLabel, textField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 7
        stackView.addArrangedSubview(fieldStack)
        textFields[key] = textField
    }

    private func addDateFields(startLabel: String, endLabel: String) {
        addTextField(key: "startDate", label: startLabel, placeholder: "Jan 2022")
        addTextField(key: "endDate", label: endLabel, placeholder: "Present")
    }

    private func addNotesField(label: String, helpText: String) {
        let fieldLabel = makeLabel(text: label, weight: .bold)
        let helpLabel = makeLabel(text: helpText, weight: .medium)
        helpLabel.textColor = AppTheme.secondaryText
        helpLabel.numberOfLines = 0
        notesTextView.heightAnchor.constraint(equalToConstant: 170).isActive = true

        let fieldStack = UIStackView(arrangedSubviews: [fieldLabel, helpLabel, notesTextView])
        fieldStack.axis = .vertical
        fieldStack.spacing = 7
        stackView.addArrangedSubview(fieldStack)
    }

    private func makeLabel(text: String, weight: UIFont.Weight) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: weight)
        label.textColor = .label
        return label
    }

    private func populateExistingEntry() {
        guard let existingEntry else { return }

        switch existingEntry {
        case .experience(let value):
            set("jobTitle", value.jobTitle)
            set("company", value.company)
            set("location", value.location)
            set("startDate", value.startDate)
            set("endDate", value.endDate)
            notesTextView.text = value.responsibilities.joined(separator: "\n")
        case .education(let value):
            set("qualification", value.qualification)
            set("institution", value.institution)
            set("fieldOfStudy", value.fieldOfStudy)
            set("startDate", value.startYear)
            set("endDate", value.endYear)
            notesTextView.text = value.details
        case .qualification(let value):
            set("title", value.title)
            set("issuer", value.issuer)
            set("year", value.year)
        case .reference(let value):
            set("name", value.name)
            set("jobTitle", value.jobTitle)
            set("company", value.company)
            set("relationship", value.relationship)
            set("email", value.email)
            set("phone", value.phone)
        }
    }

    private func set(_ key: String, _ value: String) {
        textFields[key]?.text = value
    }

    private func value(_ key: String) -> String {
        return textFields[key]?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var noteLines: [String] {
        return notesTextView.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @objc private func saveTapped() {
        guard let entry = makeEntry() else { return }
        onSave?(entry)
        navigationController?.popViewController(animated: true)
    }

    private func makeEntry() -> CVEditorEntry? {
        switch section {
        case .experience:
            guard require("jobTitle", message: "Add the job title."),
                  require("company", message: "Add the company or organisation.") else {
                return nil
            }
            return .experience(
                CVWorkExperience(
                    id: existingEntry?.id ?? UUID().uuidString,
                    jobTitle: value("jobTitle"),
                    company: value("company"),
                    location: value("location"),
                    startDate: value("startDate"),
                    endDate: value("endDate"),
                    responsibilities: noteLines
                )
            )
        case .education:
            guard require("qualification", message: "Add the qualification name."),
                  require("institution", message: "Add the institution.") else {
                return nil
            }
            return .education(
                CVEducationEntry(
                    id: existingEntry?.id ?? UUID().uuidString,
                    qualification: value("qualification"),
                    institution: value("institution"),
                    fieldOfStudy: value("fieldOfStudy"),
                    startYear: value("startDate"),
                    endYear: value("endDate"),
                    details: notesTextView.text
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        case .qualifications:
            guard require("title", message: "Add the certificate or qualification name.") else {
                return nil
            }
            return .qualification(
                CVQualificationEntry(
                    id: existingEntry?.id ?? UUID().uuidString,
                    title: value("title"),
                    issuer: value("issuer"),
                    year: value("year")
                )
            )
        case .references:
            guard require("name", message: "Add the reference's full name.") else {
                return nil
            }
            guard !value("email").isEmpty || !value("phone").isEmpty else {
                showAlert("Add an email address or phone number for this reference.")
                return nil
            }
            return .reference(
                CVReference(
                    id: existingEntry?.id ?? UUID().uuidString,
                    name: value("name"),
                    jobTitle: value("jobTitle"),
                    company: value("company"),
                    relationship: value("relationship"),
                    email: value("email"),
                    phone: value("phone")
                )
            )
        }
    }

    private func require(_ key: String, message: String) -> Bool {
        guard !value(key).isEmpty else {
            showAlert(message)
            return false
        }
        return true
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Information Needed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension UITextField {
    func setLeftPadding(_ value: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        leftView = paddingView
        leftViewMode = .always
    }
}
