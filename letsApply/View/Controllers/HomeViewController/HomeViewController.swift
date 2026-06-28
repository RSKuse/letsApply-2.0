//
//  HomeViewController.swift
//  letsApply
//

import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let firestoreService = FirestoreService()
    private var featuredJobs: [Job] = []
    private var pickedForYouJobs: [Job] = []
    private let advertHeaderView = AdvertContainerView()
    private let sections = ["Featured", "Picked For You"]
    private var lastHeaderWidth: CGFloat = 0

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "briefcase.fill")
        imageView.tintColor = AppTheme.brand
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var jobTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.background
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupUI()
        setupNavigationBar()
        registerCells()
        configureHeaderView()
        fetchJobs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeHeaderIfNeeded()
    }

    private func setupUI() {
        view.addSubview(jobTableView)

        NSLayoutConstraint.activate([
            jobTableView.topAnchor.constraint(equalTo: view.topAnchor),
            jobTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            jobTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            jobTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.titleView = logoImageView

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 26),
            logoImageView.widthAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func registerCells() {
        jobTableView.register(FeaturedJobsTableViewCell.self, forCellReuseIdentifier: FeaturedJobsTableViewCell.reuseIdentifier)
        jobTableView.register(JobTableViewCell.self, forCellReuseIdentifier: JobTableViewCell.reuseIdentifier)
    }

    private func configureHeaderView() {
        advertHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 210)
        jobTableView.tableHeaderView = advertHeaderView
        lastHeaderWidth = view.bounds.width
    }

    private func resizeHeaderIfNeeded() {
        guard view.bounds.width != lastHeaderWidth else { return }
        advertHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 210)
        jobTableView.tableHeaderView = advertHeaderView
        lastHeaderWidth = view.bounds.width
    }

    private func fetchJobs() {
        firestoreService.fetchJobs { [weak self] jobs in
            guard let self = self else { return }

            let featured = jobs.filter { $0.isFeatured }
            let regular = jobs.filter { !$0.isFeatured }

            self.featuredJobs = featured.isEmpty ? Array(jobs.prefix(5)) : featured
            self.pickedForYouJobs = regular.isEmpty ? jobs : regular

            DispatchQueue.main.async {
                self.jobTableView.reloadData()
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return featuredJobs.isEmpty ? 0 : 1
        }

        return pickedForYouJobs.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 224 : 144
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 58
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = TableSectionHeaderView()
        headerView.title = sections[section]
        headerView.seeAllButton.tag = section
        headerView.seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedJobsTableViewCell.reuseIdentifier, for: indexPath) as! FeaturedJobsTableViewCell
            cell.featuredJobsArray = featuredJobs
            cell.didSelectJob = { [weak self] job in
                self?.openJobDetails(job)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: JobTableViewCell.reuseIdentifier, for: indexPath) as! JobTableViewCell
        cell.configure(with: pickedForYouJobs[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 {
            openJobDetails(pickedForYouJobs[indexPath.row])
        }
    }

    private func openJobDetails(_ job: Job) {
        let detailsVC = JobDetailsViewController(job: job)
        detailsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    @objc private func seeAllButtonTapped(sender: UIButton) {
        let jobsToShow = sender.tag == 0 ? featuredJobs : pickedForYouJobs
        let navigationTitle = sender.tag == 0 ? "Featured Jobs" : "Picked For You"
        let jobsVC = JobsCollectionViewController(jobs: jobsToShow, navigationTitle: navigationTitle)
        jobsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(jobsVC, animated: true)
    }
}
