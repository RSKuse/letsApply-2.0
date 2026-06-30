//
//  SplashViewController.swift
//  letsApply
//

import UIKit

class SplashViewController: UIViewController {

    private lazy var viewModel = SplashViewModel()

    private lazy var markContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "app_logo"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.text = "CAREER OPERATING SYSTEM"
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.textColor = AppTheme.cyan
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Let's Apply"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "Find work that fits your future."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.white.withAlphaComponent(0.68)
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = AppTheme.brandBright
        indicator.alpha = 0
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.ink
        setupUI()
        animateSplash()
    }

    private func setupUI() {
        view.addSubview(markContainerView)
        markContainerView.addSubview(logoImageView)
        view.addSubview(eyebrowLabel)
        view.addSubview(titleLabel)
        view.addSubview(taglineLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            markContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            markContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -86),
            markContainerView.widthAnchor.constraint(equalToConstant: 88),
            markContainerView.heightAnchor.constraint(equalToConstant: 88),

            logoImageView.centerXAnchor.constraint(equalTo: markContainerView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: markContainerView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalTo: markContainerView.widthAnchor),
            logoImageView.heightAnchor.constraint(equalTo: markContainerView.heightAnchor),

            eyebrowLabel.topAnchor.constraint(equalTo: markContainerView.bottomAnchor, constant: 28),
            eyebrowLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            eyebrowLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: eyebrowLabel.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            taglineLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            taglineLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 34)
        ])
    }

    private func animateSplash() {
        markContainerView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        activityIndicator.startAnimating()

        UIView.animate(withDuration: 0.75, delay: 0.15, options: .curveEaseOut) {
            self.markContainerView.alpha = 1
            self.markContainerView.transform = .identity
            self.eyebrowLabel.alpha = 1
            self.titleLabel.alpha = 1
            self.taglineLabel.alpha = 1
            self.activityIndicator.alpha = 1
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
