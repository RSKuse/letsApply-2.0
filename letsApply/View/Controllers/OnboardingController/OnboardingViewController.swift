//
//  OnboardingViewController.swift
//  letsApply
//

import UIKit

class OnboardingViewController: UIViewController {

    private struct Slide {
        let eyebrow: String
        let title: String
        let description: String
        let metric: String
        let systemImageName: String
    }

    private let slides = [
        Slide(
            eyebrow: "DISCOVER",
            title: "Find work built around your future",
            description: "Explore trusted roles across South Africa, remote teams, and growing industries.",
            metric: "LIVE OPPORTUNITIES",
            systemImageName: "scope"
        ),
        Slide(
            eyebrow: "BUILD",
            title: "Turn your experience into a strong profile",
            description: "Keep your skills, education, qualifications, and career story ready in one place.",
            metric: "ONE CAREER PROFILE",
            systemImageName: "person.text.rectangle.fill"
        ),
        Slide(
            eyebrow: "APPLY",
            title: "Review every application before it moves",
            description: "Prepare a tailored CV draft, cover letter, and recruiter email for your approval.",
            metric: "SMART APPLICATION PACKAGE",
            systemImageName: "wand.and.stars"
        )
    ]

    private lazy var onboardingCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = AppTheme.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            OnboardingCell.self,
            forCellWithReuseIdentifier: OnboardingCell.identifier
        )
        return collectionView
    }()

    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = slides.count
        pageControl.currentPageIndicatorTintColor = AppTheme.brand
        pageControl.pageIndicatorTintColor = AppTheme.border
        pageControl.allowsContinuousInteraction = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    private lazy var primaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Continue",
            systemImageName: "arrow.right"
        )
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var continueAsGuestButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Explore as Guest"
        configuration.image = UIImage(systemName: "person.crop.circle")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        button.configuration = configuration
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(continueAsGuestTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var reassuranceLabel: UILabel = {
        let label = UILabel()
        label.text = "Free to explore. Your approval always comes first."
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupNavigationBar()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        onboardingCollectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.titleView = makeBrandTitleView()
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
        view.addSubview(primaryButton)
        view.addSubview(continueAsGuestButton)
        view.addSubview(reassuranceLabel)

        NSLayoutConstraint.activate([
            onboardingCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            onboardingCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            onboardingCollectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -16),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -20),

            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            primaryButton.bottomAnchor.constraint(equalTo: continueAsGuestButton.topAnchor, constant: -8),
            primaryButton.heightAnchor.constraint(equalToConstant: 54),

            continueAsGuestButton.leadingAnchor.constraint(equalTo: primaryButton.leadingAnchor),
            continueAsGuestButton.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            continueAsGuestButton.bottomAnchor.constraint(equalTo: reassuranceLabel.topAnchor, constant: -2),
            continueAsGuestButton.heightAnchor.constraint(equalToConstant: 42),

            reassuranceLabel.leadingAnchor.constraint(equalTo: primaryButton.leadingAnchor),
            reassuranceLabel.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            reassuranceLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    private func makeBrandTitleView() -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: "briefcase.fill"))
        iconView.tintColor = AppTheme.brand
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "Let's Apply"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [iconView, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return stackView
    }

    private func moveToNextSlide() {
        let nextPage = min(pageControl.currentPage + 1, slides.count - 1)
        onboardingCollectionView.scrollToItem(
            at: IndexPath(item: nextPage, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        updateCurrentPage(nextPage)
    }

    private func updateCurrentPage(_ page: Int) {
        pageControl.currentPage = page
        let isLastPage = page == slides.count - 1
        primaryButton.configuration = AppTheme.primaryButtonConfiguration(
            title: isLastPage ? "Create Profile" : "Continue",
            systemImageName: isLastPage ? "person.badge.plus" : "arrow.right"
        )
    }

    @objc private func continueAsGuestTapped() {
        FirebaseAuthenticationService.shared.signUpAnonymously { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.showAlert(title: "Guest Mode Failed", message: error.localizedDescription)
                } else {
                    OnboardingState.markCompleted()
                    AppRouter.showMainApp()
                }
            }
        }
    }

    @objc private func primaryButtonTapped() {
        if pageControl.currentPage == slides.count - 1 {
            navigationController?.pushViewController(SignUpViewController(), animated: true)
        } else {
            moveToNextSlide()
        }
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

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingCell.identifier,
            for: indexPath
        ) as? OnboardingCell else {
            return UICollectionViewCell()
        }

        let slide = slides[indexPath.item]
        cell.configure(
            eyebrow: slide.eyebrow,
            title: slide.title,
            description: slide.description,
            metric: slide.metric,
            systemImageName: slide.systemImageName
        )
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

        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        guard page >= 0, page < slides.count, page != pageControl.currentPage else { return }
        updateCurrentPage(page)
    }
}
