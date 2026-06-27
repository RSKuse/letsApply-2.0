//
//  CVSectionEditorViewController.swift
//  letsApply
//

import UIKit

enum CVSectionKind: CaseIterable {
    case experience
    case education
    case qualifications
    case references

    var title: String {
        switch self {
        case .experience:
            return "Work Experience"
        case .education:
            return "Education"
        case .qualifications:
            return "Qualifications"
        case .references:
            return "References"
        }
    }

    var iconName: String {
        switch self {
        case .experience:
            return "briefcase.fill"
        case .education:
            return "graduationcap.fill"
        case .qualifications:
            return "checkmark.seal.fill"
        case .references:
            return "person.2.fill"
        }
    }

    var guidance: String {
        switch self {
        case .experience:
            return "Separate every role so recruiters can scan your career timeline."
        case .education:
            return "Add each qualification with its institution and completion year."
        case .qualifications:
            return "Include certificates, licences, short courses, and professional registrations."
        case .references:
            return "Add up to three professional referees, with their permission. If empty, the CV will say available on request."
        }
    }

    var emptyMessage: String {
        switch self {
        case .experience:
            return "No structured roles yet."
        case .education:
            return "No education entries yet."
        case .qualifications:
            return "No qualifications entered yet."
        case .references:
            return "No references entered yet."
        }
    }
}

enum CVEditorEntry {
    case experience(CVWorkExperience)
    case education(CVEducationEntry)
    case qualification(CVQualificationEntry)
    case reference(CVReference)

    var id: String {
        switch self {
        case .experience(let entry):
            return entry.id
        case .education(let entry):
            return entry.id
        case .qualification(let entry):
            return entry.id
        case .reference(let entry):
            return entry.id
        }
    }
}

final class CVSectionEditorViewController: UIViewController {

    var onProfileChanged: ((UserProfile) -> Void)?

    private let section: CVSectionKind
    private var profile: UserProfile

    private lazy var guidanceLabel: UILabel = {
        let label = UILabel()
        label.text = section.guidance
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppTheme.background
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(section: CVSectionKind, profile: UserProfile) {
        self.section = section
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = section.title
        setupNavigationBar()
        setupUI()
        updateEmptyState()
        updateAddButtonState()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addEntryTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Add \(section.title)"
    }

    private func setupUI() {
        view.addSubview(guidanceLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            guidanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            guidanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            guidanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private var entries: [CVEditorEntry] {
        switch section {
        case .experience:
            return profile.workExperiences.map(CVEditorEntry.experience)
        case .education:
            return profile.educationEntries.map(CVEditorEntry.education)
        case .qualifications:
            return profile.qualificationEntries.map(CVEditorEntry.qualification)
        case .references:
            return profile.references.map(CVEditorEntry.reference)
        }
    }

    private func updateEmptyState() {
        guard entries.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = "\(section.emptyMessage)\nTap + to add one."
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        tableView.backgroundView = label
    }

    @objc private func addEntryTapped() {
        guard section != .references || profile.references.count < 3 else {
            showReferenceLimitAlert()
            return
        }
        openForm(entry: nil)
    }

    private func openForm(entry: CVEditorEntry?) {
        let formViewController = CVEntryFormViewController(section: section, entry: entry)
        formViewController.onSave = { [weak self] savedEntry in
            self?.save(entry: savedEntry, replacingID: entry?.id)
        }
        navigationController?.pushViewController(formViewController, animated: true)
    }

    private func save(entry: CVEditorEntry, replacingID: String?) {
        switch entry {
        case .experience(let experience):
            replaceOrAppend(&profile.workExperiences, value: experience, replacingID: replacingID)
            profile.experience = profile.workExperiences
                .map { entry in
                    let heading = [entry.jobTitle, entry.company]
                        .filter { !$0.isEmpty }
                        .joined(separator: " at ")
                    let details = entry.responsibilities.joined(separator: " ")
                    return [heading, details].filter { !$0.isEmpty }.joined(separator: ": ")
                }
                .joined(separator: "\n")
        case .education(let education):
            replaceOrAppend(&profile.educationEntries, value: education, replacingID: replacingID)
            profile.education = profile.educationEntries
                .map { entry in
                    [entry.qualification, entry.institution, entry.fieldOfStudy]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                }
                .joined(separator: "\n")
        case .qualification(let qualification):
            replaceOrAppend(
                &profile.qualificationEntries,
                value: qualification,
                replacingID: replacingID
            )
            profile.qualifications = profile.qualificationEntries.map(\.title)
        case .reference(let reference):
            replaceOrAppend(&profile.references, value: reference, replacingID: replacingID)
        }

        tableView.reloadData()
        updateEmptyState()
        updateAddButtonState()
        onProfileChanged?(profile)
    }

    private func replaceOrAppend<T: Identifiable>(
        _ values: inout [T],
        value: T,
        replacingID: String?
    ) where T.ID == String {
        if let replacingID,
           let index = values.firstIndex(where: { $0.id == replacingID }) {
            values[index] = value
        } else {
            values.append(value)
        }
    }

    private func deleteEntry(at index: Int) {
        switch section {
        case .experience:
            profile.workExperiences.remove(at: index)
            profile.experience = profile.workExperiences
                .flatMap(\.responsibilities)
                .joined(separator: "\n")
        case .education:
            profile.educationEntries.remove(at: index)
            profile.education = profile.educationEntries
                .map(\.qualification)
                .joined(separator: "\n")
        case .qualifications:
            profile.qualificationEntries.remove(at: index)
            profile.qualifications = profile.qualificationEntries.map(\.title)
        case .references:
            profile.references.remove(at: index)
        }

        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        updateEmptyState()
        updateAddButtonState()
        onProfileChanged?(profile)
    }

    private func updateAddButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = section != .references
            || profile.references.count < 3
    }

    private func showReferenceLimitAlert() {
        let alert = UIAlertController(
            title: "Three References Added",
            message: "Edit or remove an existing reference before adding another.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func titleAndSubtitle(for entry: CVEditorEntry) -> (String, String) {
        switch entry {
        case .experience(let value):
            let subtitle = [
                value.company,
                value.location,
                value.dateRange
            ]
            .filter { !$0.isEmpty }
            .joined(separator: "  |  ")
            return (value.jobTitle, subtitle)
        case .education(let value):
            let subtitle = [value.institution, value.dateRange]
                .filter { !$0.isEmpty }
                .joined(separator: "  |  ")
            return (value.qualification, subtitle)
        case .qualification(let value):
            let subtitle = [value.issuer, value.year]
                .filter { !$0.isEmpty }
                .joined(separator: "  |  ")
            return (value.title, subtitle)
        case .reference(let value):
            let role = [value.jobTitle, value.company]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            let contact = [value.email, value.phone]
                .filter { !$0.isEmpty }
                .joined(separator: "  |  ")
            return (value.name, [role, contact].filter { !$0.isEmpty }.joined(separator: "\n"))
        }
    }
}

extension CVSectionEditorViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let reuseIdentifier = "CVSectionEntryCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        let entry = entries[indexPath.row]
        let content = titleAndSubtitle(for: entry)

        cell.textLabel?.text = content.0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        cell.detailTextLabel?.text = content.1
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        cell.detailTextLabel?.textColor = AppTheme.secondaryText
        cell.detailTextLabel?.numberOfLines = 2
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = AppTheme.surface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openForm(entry: entries[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            self?.deleteEntry(at: indexPath.row)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
