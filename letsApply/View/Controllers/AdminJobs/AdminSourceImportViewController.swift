//
//  AdminSourceImportViewController.swift
//  letsApply
//

import UIKit

final class AdminSourceImportViewController: UIViewController {

    var onPublished: (() -> Void)?

    private let importService = JobSourceImportService()
    private let firestoreService = FirestoreService()
    private let isDebugMode: Bool
    private var jobs: [Job] = []
    private var selectedJobIds = Set<String>()
    private var didRunDebugAutomation = false

    private lazy var sourceField: UITextField = {
        let field = UITextField()
        field.placeholder = "Paste Greenhouse, Lever, or DPSA source URL"
        field.keyboardType = .URL
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.textContentType = .URL
        field.backgroundColor = AppTheme.surface
        field.layer.cornerRadius = AppTheme.cardRadius
        field.layer.borderColor = AppTheme.border.cgColor
        field.layer.borderWidth = 1
        field.setLeftPaddingPoints(14)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var analyzeButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Detect and Preview",
            systemImageName: "sparkle.magnifyingglass"
        )
        button.addTarget(self, action: #selector(analyzeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var guidanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Supported now: official Greenhouse and Lever company boards. DPSA uses the protected weekly importer. Restricted job boards require approved partner access."
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Paste an approved source to begin."
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = AppTheme.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = AppTheme.background
        table.separatorStyle = .none
        table.rowHeight = 116
        table.dataSource = self
        table.delegate = self
        table.register(
            ImportedVacancyPreviewCell.self,
            forCellReuseIdentifier: ImportedVacancyPreviewCell.reuseIdentifier
        )
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Publish Selected",
            systemImageName: "arrow.up.circle.fill"
        )
        button.isEnabled = false
        button.configuration?.baseBackgroundColor = .systemGray
        button.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(isDebugMode: Bool = false) {
        self.isDebugMode = isDebugMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Import Source"
        view.backgroundColor = AppTheme.background
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if DEBUG
        guard !didRunDebugAutomation,
              let url = ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_IMPORT_URL"],
              !url.isEmpty else {
            return
        }
        didRunDebugAutomation = true
        sourceField.text = url
        analyzeTapped()
        #endif
    }

    private func setupUI() {
        view.addSubview(sourceField)
        view.addSubview(analyzeButton)
        view.addSubview(guidanceLabel)
        view.addSubview(statusLabel)
        view.addSubview(tableView)
        view.addSubview(publishButton)

        NSLayoutConstraint.activate([
            sourceField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            sourceField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sourceField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sourceField.heightAnchor.constraint(equalToConstant: 52),

            analyzeButton.topAnchor.constraint(equalTo: sourceField.bottomAnchor, constant: 12),
            analyzeButton.leadingAnchor.constraint(equalTo: sourceField.leadingAnchor),
            analyzeButton.trailingAnchor.constraint(equalTo: sourceField.trailingAnchor),
            analyzeButton.heightAnchor.constraint(equalToConstant: 52),

            guidanceLabel.topAnchor.constraint(equalTo: analyzeButton.bottomAnchor, constant: 12),
            guidanceLabel.leadingAnchor.constraint(equalTo: sourceField.leadingAnchor),
            guidanceLabel.trailingAnchor.constraint(equalTo: sourceField.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 14),
            statusLabel.leadingAnchor.constraint(equalTo: sourceField.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: sourceField.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: publishButton.topAnchor, constant: -10),

            publishButton.leadingAnchor.constraint(equalTo: sourceField.leadingAnchor),
            publishButton.trailingAnchor.constraint(equalTo: sourceField.trailingAnchor),
            publishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            publishButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func analyzeTapped() {
        view.endEditing(true)
        setLoading(true)
        jobs = []
        selectedJobIds = []
        tableView.reloadData()

        importService.importVacancies(from: sourceField.text ?? "") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setLoading(false)
                switch result {
                case .success(let jobs):
                    self.jobs = jobs
                    self.selectedJobIds = Set(jobs.compactMap(\.id))
                    self.statusLabel.text = "\(jobs.count) vacancies found. Review and deselect anything you do not want to publish."
                    self.tableView.reloadData()
                    self.updatePublishButton()
                case .failure(let error):
                    self.statusLabel.text = error.localizedDescription
                    let isPartnerError = (error as? JobSourceImportService.ImportError).map {
                        if case .partnerAccessRequired = $0 { return true }
                        return false
                    } ?? false
                    self.showAlert(
                        title: isPartnerError ? "Partner Access Required" : "Source Not Imported",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    @objc private func publishTapped() {
        let selectedJobs = jobs.filter { job in
            guard let id = job.id else { return false }
            return selectedJobIds.contains(id)
        }
        guard !selectedJobs.isEmpty else { return }

        if isDebugMode {
            showSuccess(count: selectedJobs.count)
            return
        }

        setPublishing(true)
        let group = DispatchGroup()
        let lock = NSLock()
        var firstError: Error?

        selectedJobs.forEach { job in
            group.enter()
            firestoreService.saveAdminJob(job) { error in
                lock.lock()
                if firstError == nil {
                    firstError = error
                }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.setPublishing(false)
            if let firstError {
                self?.showAlert(
                    title: "Vacancies Not Published",
                    message: firstError.localizedDescription
                )
            } else {
                self?.showSuccess(count: selectedJobs.count)
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        sourceField.isEnabled = !loading
        analyzeButton.isEnabled = !loading
        analyzeButton.configuration?.title = loading ? "Checking Source..." : "Detect and Preview"
        analyzeButton.configuration?.showsActivityIndicator = loading
        statusLabel.text = loading ? "Reading the provider’s approved public feed..." : statusLabel.text
        updatePublishButton()
    }

    private func setPublishing(_ publishing: Bool) {
        sourceField.isEnabled = !publishing
        analyzeButton.isEnabled = !publishing
        tableView.isUserInteractionEnabled = !publishing
        publishButton.isEnabled = !publishing
        publishButton.configuration?.title = publishing ? "Publishing..." : "Publish Selected"
        publishButton.configuration?.showsActivityIndicator = publishing
    }

    private func updatePublishButton() {
        let enabled = !selectedJobIds.isEmpty && analyzeButton.isEnabled
        publishButton.isEnabled = enabled
        publishButton.configuration?.baseBackgroundColor = enabled ? AppTheme.brand : .systemGray
        publishButton.configuration?.title = selectedJobIds.isEmpty
            ? "Select Vacancies"
            : "Publish \(selectedJobIds.count) Selected"
    }

    private func showSuccess(count: Int) {
        let alert = UIAlertController(
            title: "Vacancies Published",
            message: "\(count) approved vacancies are now available in Manage Jobs and visible to candidates while they remain open.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.onPublished?()
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

extension AdminSourceImportViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        jobs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImportedVacancyPreviewCell.reuseIdentifier,
            for: indexPath
        ) as! ImportedVacancyPreviewCell
        let job = jobs[indexPath.row]
        cell.configure(
            with: job,
            selected: job.id.map(selectedJobIds.contains) ?? false
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let id = jobs[indexPath.row].id else { return }
        if selectedJobIds.contains(id) {
            selectedJobIds.remove(id)
        } else {
            selectedJobIds.insert(id)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updatePublishButton()
    }
}

private final class ImportedVacancyPreviewCell: UITableViewCell {

    static let reuseIdentifier = "ImportedVacancyPreviewCell"

    private let cardView = UIView()
    private let selectionImageView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let methodLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        cardView.backgroundColor = AppTheme.surface
        cardView.layer.cornerRadius = AppTheme.cardRadius
        cardView.layer.borderColor = AppTheme.border.cgColor
        cardView.layer.borderWidth = 1
        cardView.translatesAutoresizingMaskIntoConstraints = false

        selectionImageView.contentMode = .scaleAspectFit
        selectionImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        detailLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        detailLabel.textColor = AppTheme.secondaryText
        detailLabel.numberOfLines = 2

        methodLabel.font = .systemFont(ofSize: 12, weight: .bold)
        methodLabel.textColor = AppTheme.brand

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, methodLabel])
        textStack.axis = .vertical
        textStack.spacing = 5
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(selectionImageView)
        cardView.addSubview(textStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            selectionImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            selectionImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            selectionImageView.widthAnchor.constraint(equalToConstant: 28),
            selectionImageView.heightAnchor.constraint(equalToConstant: 28),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: selectionImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with job: Job, selected: Bool) {
        selectionImageView.image = UIImage(
            systemName: selected ? "checkmark.circle.fill" : "circle"
        )
        selectionImageView.tintColor = selected ? AppTheme.brand : AppTheme.secondaryText
        titleLabel.text = job.title
        detailLabel.text = "\(job.companyName) · \(job.locationText.isEmpty ? "Location not specified" : job.locationText)"
        methodLabel.text = "OFFICIAL SOURCE · EMPLOYER WEBSITE"
    }
}
