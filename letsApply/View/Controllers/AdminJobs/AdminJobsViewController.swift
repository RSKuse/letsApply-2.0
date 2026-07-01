//
//  AdminJobsViewController.swift
//  letsApply
//

import UIKit

class AdminJobsViewController: UIViewController {

    private let firestoreService = FirestoreService()
    private let isDebugMode: Bool
    private var jobs: [Job] = []

    private lazy var summaryView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.ink
        view.layer.cornerRadius = AppTheme.cardRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var summaryEyebrowLabel: UILabel = {
        let label = UILabel()
        label.text = "PUBLISHING CONTROL"
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = AppTheme.cyan
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Vacancy operations"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading vacancy status..."
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.70)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Live", "Drafts", "Paused", "Expired"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = AppTheme.brand
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = AppTheme.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 132
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            AdminJobTableViewCell.self,
            forCellReuseIdentifier: AdminJobTableViewCell.reuseIdentifier
        )
        tableView.refreshControl = refreshControl
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = AppTheme.brand
        control.addTarget(self, action: #selector(refreshJobs), for: .valueChanged)
        return control
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No vacancies in this status."
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        title = "Manage Jobs"
        view.backgroundColor = AppTheme.background
        setupNavigationBar()
        setupUI()
        fetchJobs()
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addJobTapped)
        )
        addButton.accessibilityLabel = "Create vacancy"
        navigationItem.rightBarButtonItem = addButton
    }

    private func setupUI() {
        view.addSubview(summaryView)
        summaryView.addSubview(summaryEyebrowLabel)
        summaryView.addSubview(summaryTitleLabel)
        summaryView.addSubview(summaryDetailLabel)
        view.addSubview(filterControl)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            summaryEyebrowLabel.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 16),
            summaryEyebrowLabel.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            summaryEyebrowLabel.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),

            summaryTitleLabel.topAnchor.constraint(equalTo: summaryEyebrowLabel.bottomAnchor, constant: 8),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryEyebrowLabel.leadingAnchor),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: summaryEyebrowLabel.trailingAnchor),

            summaryDetailLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 8),
            summaryDetailLabel.leadingAnchor.constraint(equalTo: summaryTitleLabel.leadingAnchor),
            summaryDetailLabel.trailingAnchor.constraint(equalTo: summaryTitleLabel.trailingAnchor),
            summaryDetailLabel.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -16),

            filterControl.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 16),
            filterControl.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor),
            filterControl.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor),
            filterControl.heightAnchor.constraint(equalToConstant: 38),

            tableView.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func fetchJobs() {
        if isDebugMode {
            jobs = Self.debugJobs()
            finishLoading()
            return
        }

        firestoreService.fetchAdminJobs { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshControl.endRefreshing()

                switch result {
                case .success(let jobs):
                    self.jobs = jobs
                    self.finishLoading()
                case .failure(let error):
                    self.showAlert(
                        title: "Jobs Could Not Load",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func finishLoading() {
        refreshControl.endRefreshing()
        updateSummary()
        tableView.reloadData()
        emptyLabel.isHidden = !filteredJobs.isEmpty
    }

    private func updateSummary() {
        let liveCount = jobs.filter { $0.resolvedPublicationStatus == .published }.count
        let draftCount = jobs.filter { $0.resolvedPublicationStatus == .draft }.count
        let expiredCount = jobs.filter { $0.resolvedPublicationStatus == .expired }.count
        summaryDetailLabel.text = "\(liveCount) live  ·  \(draftCount) drafts  ·  \(expiredCount) expired"
    }

    private var selectedStatus: JobPublicationStatus {
        switch filterControl.selectedSegmentIndex {
        case 1:
            return .draft
        case 2:
            return .paused
        case 3:
            return .expired
        default:
            return .published
        }
    }

    private var filteredJobs: [Job] {
        jobs.filter { $0.resolvedPublicationStatus == selectedStatus }
    }

    private func openEditor(job: Job? = nil) {
        let editor = AdminJobEditorViewController(
            job: job,
            isDebugMode: isDebugMode
        )
        editor.onSaved = { [weak self] in
            self?.fetchJobs()
        }
        editor.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(editor, animated: true)
    }

    private func changeStatus(for job: Job, to status: JobPublicationStatus) {
        guard let jobId = job.id else { return }

        if isDebugMode {
            jobs = jobs.map {
                $0.id == jobId ? Self.copy($0, status: status) : $0
            }
            finishLoading()
            return
        }

        firestoreService.updateJobPublicationStatus(
            jobId: jobId,
            status: status
        ) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(title: "Status Not Updated", message: error.localizedDescription)
                } else {
                    self?.fetchJobs()
                }
            }
        }
    }

    private func confirmPermanentDeletion(of job: Job) {
        guard let jobId = job.id else { return }

        let alert = UIAlertController(
            title: "Delete Expired Vacancy?",
            message: "\"\(job.title)\" will be permanently removed. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Permanently", style: .destructive) { [weak self] _ in
            self?.deleteExpiredJob(jobId: jobId)
        })
        present(alert, animated: true)
    }

    private func deleteExpiredJob(jobId: String) {
        if isDebugMode {
            jobs.removeAll { $0.id == jobId }
            finishLoading()
            return
        }

        firestoreService.deleteAdminJob(jobId: jobId) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(
                        title: "Vacancy Not Deleted",
                        message: error.localizedDescription
                    )
                } else {
                    self?.fetchJobs()
                }
            }
        }
    }

    @objc private func refreshJobs() {
        fetchJobs()
    }

    @objc private func filterChanged() {
        tableView.reloadData()
        emptyLabel.isHidden = !filteredJobs.isEmpty
    }

    @objc private func addJobTapped() {
        openEditor()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AdminJobsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredJobs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AdminJobTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! AdminJobTableViewCell
        cell.configure(with: filteredJobs[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openEditor(job: filteredJobs[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let job = filteredJobs[indexPath.row]

        if job.resolvedPublicationStatus == .expired {
            let deleteAction = UIContextualAction(
                style: .destructive,
                title: "Delete"
            ) { [weak self] _, _, completion in
                self?.confirmPermanentDeletion(of: job)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "trash.fill")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }

        guard job.resolvedPublicationStatus == .published else { return nil }

        let pauseAction = UIContextualAction(
            style: .normal,
            title: "Pause"
        ) { [weak self] _, _, completion in
            self?.changeStatus(for: job, to: .paused)
            completion(true)
        }
        pauseAction.backgroundColor = AppTheme.amber
        pauseAction.image = UIImage(systemName: "pause.fill")
        return UISwipeActionsConfiguration(actions: [pauseAction])
    }
}

private extension AdminJobsViewController {

    static func debugJobs() -> [Job] {
        let samples = FirestoreService.sampleJobs()
        guard samples.count >= 3 else { return samples }

        return [
            copy(samples[0], status: .published, closingDate: "2026-12-18"),
            copy(samples[1], status: .draft, closingDate: "2026-11-30"),
            copy(samples[2], status: .published, closingDate: "2026-01-15")
        ]
    }

    static func copy(
        _ job: Job,
        status: JobPublicationStatus,
        closingDate: String? = nil
    ) -> Job {
        Job(
            id: job.id,
            title: job.title,
            companyName: job.companyName,
            companyImageName: job.companyImageName,
            companyLogoURL: job.companyLogoURL,
            location: job.location,
            jobType: job.jobType,
            remote: job.remote,
            description: job.description,
            qualifications: job.qualifications,
            responsibilities: job.responsibilities,
            requirements: job.requirements,
            experience: job.experience,
            compensation: job.compensation,
            application: job.application,
            jobCategory: job.jobCategory,
            postingDate: job.postingDate,
            visibility: job.visibility,
            promoted: job.promoted,
            sourceName: job.sourceName,
            sourceUrl: job.sourceUrl,
            sourceJobId: job.sourceJobId,
            sourceType: job.sourceType,
            dateImported: job.dateImported,
            verified: job.verified,
            closingDate: closingDate ?? job.closingDate,
            publicationStatus: status.rawValue
        )
    }
}
