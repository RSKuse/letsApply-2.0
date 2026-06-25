//
//  JobsViewController.swift
//  letsApply
//

import UIKit

class JobsViewController: UIViewController {

    private let viewModel = JobViewModel()
    private var jobs: [Job] = []
    private var filteredJobs: [Job] = []

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search jobs, companies, skills"
        return controller
    }()

    private lazy var jobsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        collectionView.register(JobCollectionViewCell.self, forCellWithReuseIdentifier: JobCollectionViewCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No jobs found yet."
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        fetchJobs()
    }

    private func setupNavigationBar() {
        title = "Jobs"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupUI() {
        view.addSubview(jobsCollectionView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            jobsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            jobsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            jobsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            jobsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func fetchJobs() {
        viewModel.fetchJobs { [weak self] fetchedJobs in
            DispatchQueue.main.async {
                self?.jobs = fetchedJobs
                self?.filteredJobs = fetchedJobs
                self?.updateEmptyState()
                self?.jobsCollectionView.reloadData()
            }
        }
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !filteredJobs.isEmpty
    }

    private func openJobDetails(_ job: Job) {
        let detailsVC = JobDetailsViewController(job: job)
        detailsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}

extension JobsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredJobs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JobCollectionViewCell.reuseIdentifier, for: indexPath) as! JobCollectionViewCell
        cell.configure(with: filteredJobs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openJobDetails(filteredJobs[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let columns: CGFloat = availableWidth > 500 ? 3 : 2
        let totalSpacing = (columns - 1) * 12
        let width = floor((availableWidth - totalSpacing) / columns)
        return CGSize(width: width, height: 210)
    }
}

extension JobsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !searchText.isEmpty else {
            filteredJobs = jobs
            updateEmptyState()
            jobsCollectionView.reloadData()
            return
        }

        filteredJobs = jobs.filter { job in
            let searchableText = [
                job.title,
                job.companyName,
                job.locationText,
                job.jobType,
                job.jobCategory,
                job.requirements.joined(separator: " "),
                job.qualifications.joined(separator: " ")
            ].joined(separator: " ").lowercased()

            return searchableText.contains(searchText)
        }

        updateEmptyState()
        jobsCollectionView.reloadData()
    }
}
