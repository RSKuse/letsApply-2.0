//
//  JobListViewController.swift
//  letsApply
//

import UIKit

class JobViewModel {
    private let firestoreService = FirestoreService()

    func fetchJobs(completion: @escaping ([Job]) -> Void) {
        firestoreService.fetchJobs { jobs in
            completion(jobs)
        }
    }
}

class JobListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let viewModel = JobViewModel()
    private var jobs: [Job] = []

    private lazy var jobCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 24, right: 0)
        collectionView.register(JobCollectionViewCell.self, forCellWithReuseIdentifier: JobCollectionViewCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Jobs"
        setupUI()
        fetchJobs()
    }

    private func setupUI() {
        view.addSubview(jobCollectionView)

        NSLayoutConstraint.activate([
            jobCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            jobCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            jobCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            jobCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func fetchJobs() {
        viewModel.fetchJobs { [weak self] fetchedJobs in
            DispatchQueue.main.async {
                self?.jobs = fetchedJobs
                self?.jobCollectionView.reloadData()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JobCollectionViewCell.reuseIdentifier, for: indexPath) as! JobCollectionViewCell
        cell.configure(with: jobs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailsVC = JobDetailsViewController(job: jobs[indexPath.item])
        detailsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 2
        let spacingBetweenItems: CGFloat = 10
        let totalSpacing = spacingBetweenItems * (numberOfItemsPerRow - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
        return CGSize(width: width, height: 220)
    }
}

class JobsCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let jobs: [Job]
    private let navigationTitle: String

    private lazy var jobsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 24, right: 0)
        collectionView.register(JobCollectionViewCell.self, forCellWithReuseIdentifier: JobCollectionViewCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    init(jobs: [Job], navigationTitle: String) {
        self.jobs = jobs
        self.navigationTitle = navigationTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = navigationTitle
        setupUI()
    }

    private func setupUI() {
        view.addSubview(jobsCollectionView)

        NSLayoutConstraint.activate([
            jobsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            jobsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            jobsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            jobsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JobCollectionViewCell.reuseIdentifier, for: indexPath) as! JobCollectionViewCell
        cell.configure(with: jobs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailsVC = JobDetailsViewController(job: jobs[indexPath.item])
        detailsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailsVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow: CGFloat = 2
        let spacingBetweenItems: CGFloat = 10
        let totalSpacing = spacingBetweenItems * (numberOfItemsPerRow - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
        return CGSize(width: width, height: 220)
    }
}
