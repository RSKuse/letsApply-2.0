//
//  AICareerToolViewController.swift
//  letsApply
//

import UIKit

class AICareerToolViewController: UIViewController {

    private let tool: AICareerService.CareerTool
    private let userProfile: UserProfile
    private let job: Job
    private let aiCareerService = AICareerService()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Premium tool for \(job.title) at \(job.companyName). The UI is ready for API integration."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var outputTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 14
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(tool: AICareerService.CareerTool, userProfile: UserProfile, job: Job) {
        self.tool = tool
        self.userProfile = userProfile
        self.job = job
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = tool.title
        setupUI()
        generateTapped()
    }

    private func setupUI() {
        view.addSubview(instructionLabel)
        view.addSubview(outputTextView)
        view.addSubview(generateButton)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            outputTextView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 18),
            outputTextView.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            outputTextView.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            outputTextView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -18),

            generateButton.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            generateButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func generateTapped() {
        generateButton.isEnabled = false

        let completion: (Result<String, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                self?.generateButton.isEnabled = true

                switch result {
                case .success(let text):
                    self?.outputTextView.text = text
                case .failure(let error):
                    self?.outputTextView.text = error.localizedDescription
                }
            }
        }

        switch tool {
        case .coverLetter:
            aiCareerService.generateCoverLetter(userProfile: userProfile, job: job, completion: completion)
        case .tailorCV:
            aiCareerService.tailorCV(userProfile: userProfile, job: job, completion: completion)
        case .improveCV:
            aiCareerService.improveCV(userProfile: userProfile, completion: completion)
        }
    }
}
