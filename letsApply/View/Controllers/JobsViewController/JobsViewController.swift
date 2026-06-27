//
//  JobsViewController.swift
//  letsApply
//

import UIKit

class JobsViewController: UIViewController {

    private let viewModel = JobViewModel()
    private var jobs: [Job] = []
    private var filteredJobs: [Job] = []
    private var activeFilters = JobFilters()
    private var selectedFilterTitle = "All"

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
        collectionView.backgroundColor = AppTheme.background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        collectionView.register(JobCollectionViewCell.self, forCellWithReuseIdentifier: JobCollectionViewCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var filterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
        view.backgroundColor = AppTheme.background
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
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        view.addSubview(jobsCollectionView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 46),

            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor, constant: 4),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 20),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -20),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: -4),
            filterStackView.heightAnchor.constraint(equalToConstant: 38),

            jobsCollectionView.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
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
                self?.buildFilterChips()
                self?.applyFilters()
            }
        }
    }

    private func buildFilterChips() {
        filterStackView.arrangedSubviews.forEach { view in
            filterStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let jobTypes = Array(Set(jobs.map { $0.jobType }.filter { !$0.isEmpty })).sorted()
        let categories = Array(Set(jobs.map { $0.jobCategory }.filter { !$0.isEmpty })).sorted()
        let titles = ["All", "Remote", "Featured"] + jobTypes + categories

        titles.prefix(14).forEach { title in
            filterStackView.addArrangedSubview(makeFilterButton(title: title))
        }
    }

    private func makeFilterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityLabel = title
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        styleFilterButton(button, selected: title == selectedFilterTitle)
        return button
    }

    private func styleFilterButton(_ button: UIButton, selected: Bool) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = button.accessibilityLabel
        configuration.baseBackgroundColor = selected ? AppTheme.brand : AppTheme.mutedSurface
        configuration.baseForegroundColor = selected ? .white : .label
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
    }

    @objc private func filterTapped(_ sender: UIButton) {
        selectedFilterTitle = sender.accessibilityLabel ?? "All"
        activeFilters = JobFilters(keyword: activeFilters.keyword)

        switch selectedFilterTitle {
        case "Remote":
            activeFilters.remoteOnly = true
        case "Featured":
            activeFilters.featuredOnly = true
        case "All":
            break
        default:
            if jobs.contains(where: { $0.jobType == selectedFilterTitle }) {
                activeFilters.jobType = selectedFilterTitle
            } else {
                activeFilters.category = selectedFilterTitle
            }
        }

        filterStackView.arrangedSubviews.compactMap { $0 as? UIButton }.forEach {
            styleFilterButton($0, selected: $0.accessibilityLabel == selectedFilterTitle)
        }
        applyFilters()
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !filteredJobs.isEmpty
    }

    private func applyFilters() {
        filteredJobs = jobs.filter { activeFilters.matches($0) }
        updateEmptyState()
        jobsCollectionView.reloadData()
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
        return CGSize(width: width, height: 220)
    }
}

extension JobsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        activeFilters.keyword = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        applyFilters()
    }
}
