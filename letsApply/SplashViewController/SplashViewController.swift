//
//  SplashViewController.swift
//  letsApply
//

import UIKit

class SplashViewController: UIViewController {

    private lazy var viewModel = SplashViewModel()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "app_logo") ?? UIImage(systemName: "briefcase.fill"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Let's Apply"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "Find work that fits your future."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        animateSplash()
    }

    private func setupUI() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(taglineLabel)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -70),
            logoImageView.widthAnchor.constraint(equalToConstant: 104),
            logoImageView.heightAnchor.constraint(equalToConstant: 104),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            taglineLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            taglineLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    private func animateSplash() {
        logoImageView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)

        UIView.animate(withDuration: 0.75, delay: 0.15, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
            self.titleLabel.alpha = 1
            self.taglineLabel.alpha = 1
        } completion: { _ in
            self.routeUser()
        }
    }

    private func routeUser() {
        viewModel.checkAuthentication { authenticationState in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                switch authenticationState {
                case .onboarding:
                    AppRouter.showOnboarding()
                case .profileSetup:
                    AppRouter.showProfileSetup()
                case .mainApp:
                    AppRouter.showMainApp()
                }
            }
        }
    }
}
