//
//  CVBuilderViewController.swift
//  letsApply
//

import UIKit

class CVBuilderViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "CV Builder"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create a clean CV draft from your profile. PDF export will connect here in the next version."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var summaryTextView: UITextView = {
        let textView = UITextView()
        textView.text = "Professional summary"
        textView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 14
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var saveDraftButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save CV Draft", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveDraftTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "CV"
        setupUI()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(summaryTextView)
        view.addSubview(saveDraftButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            summaryTextView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            summaryTextView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            summaryTextView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            summaryTextView.heightAnchor.constraint(equalToConstant: 240),

            saveDraftButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            saveDraftButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            saveDraftButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            saveDraftButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func saveDraftTapped() {
        let alert = UIAlertController(
            title: "CV Draft Saved",
            message: "Your CV draft area is ready. PDF generation and file upload can connect here next.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
