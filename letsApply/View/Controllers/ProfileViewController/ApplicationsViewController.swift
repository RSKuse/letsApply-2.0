//
//  ApplicationsViewController.swift
//  letsApply
//

import UIKit

class ApplicationsViewController: UIViewController {

    private let userId: String
    private let firestoreService = FirestoreService()
    private var applications: [Application] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.background
        tableView.register(ApplicationTableViewCell.self, forCellReuseIdentifier: ApplicationTableViewCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Applications you submit will appear here."
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
        title = "Applications"
        view.backgroundColor = AppTheme.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        setupUI()
        fetchApplications()
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

    private func fetchApplications() {
        firestoreService.fetchApplications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let applications):
                    self.applications = applications
                    self.emptyLabel.isHidden = !applications.isEmpty
                    self.tableView.reloadData()
                case .failure(let error):
                    self.showAlert(title: "Load Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func refreshTapped() {
        fetchApplications()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ApplicationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applications.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 154
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ApplicationTableViewCell.reuseIdentifier, for: indexPath) as! ApplicationTableViewCell
        let application = applications[indexPath.row]
        cell.configure(with: application)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let application = applications[indexPath.row]

        firestoreService.fetchJob(jobId: application.jobId) { [weak self] result in
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
}
