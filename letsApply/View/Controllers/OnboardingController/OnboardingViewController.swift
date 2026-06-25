//
//  OnboardingViewController.swift
//  letsApply
//

import UIKit

class OnboardingViewController: UIViewController {

    private let slides = [
        ("Find jobs that match your future", "Browse trusted opportunities across South Africa and build momentum without clutter.", "magnifyingglass"),
        ("Build a profile employers can trust", "Create a clean career profile with skills, education, experience, and your CV.", "person.text.rectangle"),
        ("Apply smarter with Let's Apply", "Save jobs, track applications, and unlock premium AI tools when you are ready.", "sparkles")
    ]

    private lazy var onboardingCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.identifier)
        return collectionView
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = slides.count
        pageControl.currentPageIndicatorTintColor = .systemGreen
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    private lazy var createProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(createProfileTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var continueAsGuestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue as Guest", for: .normal)
        button.setTitleColor(.systemGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(continueAsGuestTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        title = "Let's Apply"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sign In",
            style: .plain,
            target: self,
            action: #selector(signInTapped)
        )
    }

    private func setupUI() {
        view.addSubview(onboardingCollectionView)
        view.addSubview(pageControl)
        view.addSubview(createProfileButton)
        view.addSubview(continueAsGuestButton)

        NSLayoutConstraint.activate([
            onboardingCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            onboardingCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            onboardingCollectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -16),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: createProfileButton.topAnchor, constant: -24),

            createProfileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createProfileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createProfileButton.bottomAnchor.constraint(equalTo: continueAsGuestButton.topAnchor, constant: -12),
            createProfileButton.heightAnchor.constraint(equalToConstant: 52),

            continueAsGuestButton.leadingAnchor.constraint(equalTo: createProfileButton.leadingAnchor),
            continueAsGuestButton.trailingAnchor.constraint(equalTo: createProfileButton.trailingAnchor),
            continueAsGuestButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            continueAsGuestButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func continueAsGuestTapped() {
        FirebaseAuthenticationService.shared.signUpAnonymously { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Guest Mode Failed", message: error.localizedDescription)
                } else {
                    AppRouter.showMainApp()
                }
            }
        }
    }

    @objc private func createProfileTapped() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func signInTapped() {
        navigationController?.pushViewController(SignInViewController(), animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingCell.identifier, for: indexPath) as? OnboardingCell else {
            return UICollectionViewCell()
        }
        let slide = slides[indexPath.item]
        cell.configure(title: slide.0, description: slide.1, systemImageName: slide.2)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
    }
}
