//
//  HomeScreenViewController.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/16.
//

//import Foundation
//import UIKit
//
//class HomeScreenViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
//    
//    private let homeViewModel = HomeViewModel()
//    private var jobs: [Job] = []
//    
//    // MARK: - UI Elements
//    
//    lazy var logoImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(named: "app_logo")
//        imageView.layer.cornerRadius = 15
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//   lazy var searchController: UISearchController = {
//        let controller = UISearchController()
//        controller.searchBar.placeholder = "Search jobs..."
//        return controller
//    }()
//    
//    lazy var jobsTableView: UITableView = {
//        let tableView = UITableView(frame: .zero, style: .plain)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.allowsSelection = true
//        tableView.separatorStyle = .none
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        return tableView
//    }()
//
//    
//    // MARK: - LifeCycle
//    
//    override func viewDidLoad() {
//        //view.backgroundColor = .white
//        super.viewDidLoad()
//        setupUI()
//        setupNavigationBar()
//        registerCell()
//        configureHeaderView()
//    }
//    
//    func setupUI() {
//        view.backgroundColor = .systemBackground
//        
//        view.addSubview(logoImageView)
//        view.addSubview(greetingLabel)
//        view.addSubview(notificationButton)
//        view.addSubview(categoriesCollectionView)
//        view.addSubview(jobsCollectionView)
//        
//        jobsTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        jobsTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        jobsTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//        jobsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        
//    }
//    
//    private func setupNavigationBar() {
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
//    }
//    
//    // MARK: - Load Data
//    
//    private func loadUserProfile() {
//        homeViewModel.fetchUserProfile { [weak self] profile in
//            self?.greetingLabel.text = "Hello, \(profile.name)!"
//            self?.homeViewModel.loadProfileImage(urlString: profile.profilePictureUrl) { image in
//                self?.profileImageView.image = image
//            }
//            self?.homeViewModel.fetchRelevantJobs(for: profile) { jobs in
//                self?.jobs = jobs
//                self?.jobsCollectionView.reloadData()
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
//
//extension HomeScreenViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == categoriesCollectionView {
//            return homeViewModel.categories.count
//        } else {
//            return jobs.count
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == categoriesCollectionView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JobCategoryCell.identifier, for: indexPath) as! JobCategoryCell
//            let category = homeViewModel.categories[indexPath.row]
//            cell.configure(with: category)
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JobCell.identifier, for: indexPath) as! JobCell
//            let job = jobs[indexPath.row]
//            cell.configure(with: job)
//            return cell
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        if collectionView == categoriesCollectionView {
//            return CGSize(width: 100, height: 100)
//        } else {
//            return CGSize(width: collectionView.frame.width, height: 120)
//        }
//    }
//}
