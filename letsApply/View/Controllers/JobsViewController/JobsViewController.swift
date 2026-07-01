//
//  JobsViewController.swift
//  letsApply
//

import UIKit

private enum JobQuickFilter: String, CaseIterable {
    case all = "All"
    case remote = "Remote"
    case hybrid = "Hybrid"
    case featured = "Featured"
    case government = "Government"
    case permanent = "Permanent"
    case contract = "Contract"
}

class JobsViewController: UIViewController {

    private let viewModel = JobViewModel()
    private var jobs: [Job] = []
    private var filteredJobs: [Job] = []
    private var selectedQuickFilter: JobQuickFilter = .all
    private var selectedDepartment = ""
    private var searchText = ""
    private var filterButtons: [JobQuickFilter: UIButton] = [:]

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

    private lazy var filterPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var filterGridStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var departmentButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "Filter by government department"
        button.accessibilityHint = "Opens a list of departments"
        button.showsMenuAsPrimaryAction = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return button
    }()

    private lazy var resultsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = AppTheme.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var clearFiltersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        button.tintColor = AppTheme.brand
        button.addTarget(self, action: #selector(clearFiltersTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        buildFilterGrid()
        view.addSubview(filterPanelView)
        filterPanelView.addSubview(filterGridStackView)
        filterPanelView.addSubview(resultsLabel)
        filterPanelView.addSubview(clearFiltersButton)
        view.addSubview(jobsCollectionView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            filterPanelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            filterGridStackView.topAnchor.constraint(equalTo: filterPanelView.topAnchor, constant: 12),
            filterGridStackView.leadingAnchor.constraint(equalTo: filterPanelView.leadingAnchor, constant: 12),
            filterGridStackView.trailingAnchor.constraint(equalTo: filterPanelView.trailingAnchor, constant: -12),

            resultsLabel.topAnchor.constraint(equalTo: filterGridStackView.bottomAnchor, constant: 10),
            resultsLabel.leadingAnchor.constraint(equalTo: filterGridStackView.leadingAnchor),
            resultsLabel.bottomAnchor.constraint(equalTo: filterPanelView.bottomAnchor, constant: -10),

            clearFiltersButton.centerYAnchor.constraint(equalTo: resultsLabel.centerYAnchor),
            clearFiltersButton.trailingAnchor.constraint(equalTo: filterGridStackView.trailingAnchor),
            clearFiltersButton.leadingAnchor.constraint(greaterThanOrEqualTo: resultsLabel.trailingAnchor, constant: 12),

            jobsCollectionView.topAnchor.constraint(equalTo: filterPanelView.bottomAnchor, constant: 4),
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
                self?.rebuildDepartmentMenu()
                self?.applyFilters()
            }
        }
    }

    private func buildFilterGrid() {
        let firstRow = makeFilterRow(for: [.all, .remote, .hybrid, .featured])
        let secondRow = makeFilterRow(
            for: [.government, .permanent, .contract],
            additionalView: departmentButton
        )
        filterGridStackView.addArrangedSubview(firstRow)
        filterGridStackView.addArrangedSubview(secondRow)
        styleAllFilterButtons()
        rebuildDepartmentMenu()
    }

    private func makeFilterRow(
        for filters: [JobQuickFilter],
        additionalView: UIView? = nil
    ) -> UIStackView {
        var views: [UIView] = filters.map { makeFilterButton(filter: $0) }
        if let additionalView {
            views.append(additionalView)
        }
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 8
        row.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return row
    }

    private func makeFilterButton(filter: JobQuickFilter) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "\(filter.rawValue) jobs"
        button.accessibilityIdentifier = filter.rawValue
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        filterButtons[filter] = button
        return button
    }

    private func styleFilterButton(
        _ button: UIButton,
        title: String,
        selected: Bool
    ) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = selected ? AppTheme.brand : AppTheme.mutedSurface
        configuration.baseForegroundColor = selected ? .white : .label
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 6, bottom: 7, trailing: 6)
        configuration.background.strokeColor = selected ? .clear : AppTheme.border
        configuration.background.strokeWidth = selected ? 0 : 1
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            return updatedAttributes
        }
        button.configuration = configuration
    }

    private func styleAllFilterButtons() {
        filterButtons.forEach { filter, button in
            styleFilterButton(
                button,
                title: filter.rawValue,
                selected: filter == selectedQuickFilter
            )
        }
        styleFilterButton(
            departmentButton,
            title: selectedDepartment.isEmpty ? "Dept." : "Dept. ✓",
            selected: !selectedDepartment.isEmpty
        )
        var departmentConfiguration = departmentButton.configuration
        departmentConfiguration?.image = UIImage(systemName: "chevron.down")
        departmentConfiguration?.imagePlacement = .trailing
        departmentConfiguration?.imagePadding = 4
        departmentButton.configuration = departmentConfiguration
    }

    private func rebuildDepartmentMenu() {
        let departments = Array(Set(
            jobs
                .filter(\.requiresGovernmentFlow)
                .map(\.companyName)
                .filter { !$0.isEmpty }
        )).sorted()

        if !selectedDepartment.isEmpty && !departments.contains(selectedDepartment) {
            selectedDepartment = ""
        }

        let allAction = UIAction(
            title: "All Departments",
            state: selectedDepartment.isEmpty ? .on : .off
        ) { [weak self] _ in
            self?.selectDepartment("")
        }
        let departmentActions = departments.map { department in
            UIAction(
                title: department,
                state: department == selectedDepartment ? .on : .off
            ) { [weak self] _ in
                self?.selectDepartment(department)
            }
        }

        departmentButton.menu = UIMenu(
            title: "Government Departments",
            children: [allAction] + departmentActions
        )
        departmentButton.isEnabled = !departments.isEmpty
        styleAllFilterButtons()
    }

    private func selectDepartment(_ department: String) {
        selectedDepartment = department
        if !department.isEmpty {
            selectedQuickFilter = .government
        }
        rebuildDepartmentMenu()
        applyFilters()
    }

    @objc private func filterTapped(_ sender: UIButton) {
        guard let identifier = sender.accessibilityIdentifier,
              let filter = JobQuickFilter(rawValue: identifier) else {
            return
        }

        selectedQuickFilter = filter
        if filter != .government {
            selectedDepartment = ""
            rebuildDepartmentMenu()
        }
        styleAllFilterButtons()
        applyFilters()
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !filteredJobs.isEmpty
        emptyStateLabel.text = "No jobs match these filters."
    }

    private func applyFilters() {
        filteredJobs = jobs.filter { job in
            matchesSearch(job)
                && selectedQuickFilter.matches(job)
                && matchesDepartment(job)
        }

        let noun = filteredJobs.count == 1 ? "opportunity" : "opportunities"
        resultsLabel.text = "\(filteredJobs.count) \(noun)"
        clearFiltersButton.isHidden = selectedQuickFilter == .all
            && selectedDepartment.isEmpty
            && searchText.isEmpty
        updateEmptyState()
        jobsCollectionView.reloadData()
    }

    private func matchesSearch(_ job: Job) -> Bool {
        guard !searchText.isEmpty else { return true }
        return JobFilters(keyword: searchText).matches(job)
    }

    private func matchesDepartment(_ job: Job) -> Bool {
        selectedDepartment.isEmpty || job.companyName == selectedDepartment
    }

    @objc private func clearFiltersTapped() {
        selectedQuickFilter = .all
        selectedDepartment = ""
        searchText = ""
        searchController.searchBar.text = ""
        rebuildDepartmentMenu()
        styleAllFilterButtons()
        applyFilters()
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
        let columns: CGFloat = availableWidth > 700 ? 2 : 1
        let totalSpacing = (columns - 1) * 12
        let width = floor((availableWidth - totalSpacing) / columns)
        return CGSize(width: width, height: columns == 1 ? 172 : 210)
    }
}

extension JobsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        applyFilters()
    }
}

private extension JobQuickFilter {

    func matches(_ job: Job) -> Bool {
        let workStyleText = [
            job.jobType,
            job.locationText,
            job.description
        ].joined(separator: " ")

        switch self {
        case .all:
            return true
        case .remote:
            return job.remote || workStyleText.localizedCaseInsensitiveContains("remote")
        case .hybrid:
            return workStyleText.localizedCaseInsensitiveContains("hybrid")
        case .featured:
            return job.isFeatured
        case .government:
            return job.requiresGovernmentFlow
        case .permanent:
            return job.jobType.localizedCaseInsensitiveContains("permanent")
        case .contract:
            return job.jobType.localizedCaseInsensitiveContains("contract")
                || job.jobType.localizedCaseInsensitiveContains("fixed term")
                || job.jobType.localizedCaseInsensitiveContains("temporary")
        }
    }
}
