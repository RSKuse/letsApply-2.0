//
//  SavedJobsViewController.swift
//  letsApply
//

import UIKit

class SavedJobsViewController: UIViewController {

    private let userId: String
    private let firestoreService = FirestoreService()
    private var savedJobs: [SavedJob] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.register(SavedJobTableViewCell.self, forCellReuseIdentifier: SavedJobTableViewCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved jobs will appear here."
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Jobs"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        setupUI()
        fetchSavedJobs()
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func fetchSavedJobs() {
        firestoreService.fetchSavedJobs(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let savedJobs):
                    self.savedJobs = savedJobs
                    self.emptyLabel.isHidden = !savedJobs.isEmpty
                    self.tableView.reloadData()
                case .failure(let error):
                    self.showAlert(title: "Load Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func refreshTapped() {
        fetchSavedJobs()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SavedJobsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedJobs.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SavedJobTableViewCell.reuseIdentifier, for: indexPath) as! SavedJobTableViewCell
        let savedJob = savedJobs[indexPath.row]
        cell.configure(with: savedJob)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let savedJob = savedJobs[indexPath.row]
        firestoreService.fetchJob(jobId: savedJob.jobId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let job):
                    let detailsVC = JobDetailsViewController(job: job)
                    detailsVC.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(detailsVC, animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Job Not Found", message: error.localizedDescription)
                }
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let savedJob = savedJobs[indexPath.row]
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }

            self.firestoreService.removeSavedJob(userId: self.userId, jobId: savedJob.jobId) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showAlert(title: "Remove Failed", message: error.localizedDescription)
                        completion(false)
                    } else {
                        self.savedJobs.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.emptyLabel.isHidden = !self.savedJobs.isEmpty
                        completion(true)
                    }
                }
            }
        }

        return UISwipeActionsConfiguration(actions: [remove])
    }
}
