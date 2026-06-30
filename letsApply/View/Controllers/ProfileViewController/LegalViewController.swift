//
//  LegalViewController.swift
//  letsApply
//

import UIKit

final class LegalViewController: UIViewController {

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Privacy & Data"
        view.backgroundColor = AppTheme.background
        setupUI()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(makeHeader())
        stackView.addArrangedSubview(makeSection(
            title: "Information You Provide",
            body: "Let’s Apply stores the profile, CV details, saved jobs, and application records you choose to create. A small compressed profile photo may be stored inside your private Firestore profile."
        ))
        stackView.addArrangedSubview(makeSection(
            title: "How It Is Used",
            body: "Your information is used to match vacancies, create application documents, remember saved jobs, and track applications. Let’s Apply does not submit or email an application without your approval."
        ))
        stackView.addArrangedSubview(makeSection(
            title: "Documents",
            body: "CV and cover-letter PDFs are generated locally on your device. When you share a document or continue to an employer website, the receiving app or employer applies its own privacy practices."
        ))
        stackView.addArrangedSubview(makeSection(
            title: "Your Control",
            body: "You can edit your profile, sign out, or permanently delete your account from the Profile screen. Account deletion removes your profile, saved jobs, applications, and Firebase sign-in account."
        ))
        stackView.addArrangedSubview(makeSection(
            title: "Vacancy Sources",
            body: "Vacancies can be curated by Let’s Apply, supplied by recruiters, or imported from identified public sources. Source and application links are shown where available. Always verify employer instructions before submitting."
        ))
        stackView.addArrangedSubview(makeSection(
            title: "Important",
            body: "Job matching and generated writing are decision-support tools, not guarantees of employment. Review every generated statement and document for accuracy before use."
        ))

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.ink
        container.layer.cornerRadius = AppTheme.cardRadius

        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = AppTheme.brandBright
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Your career data stays under your control."
        title.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        title.textColor = .white
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false

        let detail = UILabel()
        detail.text = "Review, edit, export, or delete it."
        detail.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        detail.textColor = UIColor.white.withAlphaComponent(0.7)
        detail.numberOfLines = 0
        detail.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(icon)
        container.addSubview(title)
        container.addSubview(detail)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 34),
            icon.heightAnchor.constraint(equalToConstant: 34),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: icon.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            detail.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    private func makeSection(title: String, body: String) -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.surface
        container.layer.cornerRadius = AppTheme.cardRadius
        container.layer.borderWidth = 1
        container.layer.borderColor = AppTheme.border.cgColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = AppTheme.secondaryText
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }
}
