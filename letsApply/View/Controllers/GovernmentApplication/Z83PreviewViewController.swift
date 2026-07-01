//
//  Z83PreviewViewController.swift
//  letsApply
//

import PDFKit
import UIKit

final class Z83PreviewViewController: UIViewController {

    var onUseForm: (() -> Void)?

    private let fileURL: URL

    private lazy var pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.backgroundColor = AppTheme.background
        view.document = PDFDocument(url: fileURL)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var useButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = AppTheme.primaryButtonConfiguration(
            title: "Use This Z83",
            systemImageName: "checkmark.circle.fill"
        )
        button.addTarget(self, action: #selector(useTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Review Z83"
        view.backgroundColor = AppTheme.background
        setupNavigationBar()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self, let firstPage = self.pdfView.document?.page(at: 0) else {
                return
            }
            self.pdfView.go(
                to: firstPage.bounds(for: .mediaBox),
                on: firstPage
            )
        }
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Share completed Z83"
    }

    private func setupUI() {
        view.addSubview(pdfView)
        view.addSubview(useButton)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: useButton.topAnchor, constant: -12),

            useButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            useButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            useButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            useButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func shareTapped() {
        let controller = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(controller, animated: true)
    }

    @objc private func useTapped() {
        onUseForm?()
        navigationController?.popViewController(animated: true)
    }
}
