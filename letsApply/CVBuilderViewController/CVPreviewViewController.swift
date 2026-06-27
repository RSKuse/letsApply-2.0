//
//  CVPreviewViewController.swift
//  letsApply
//

import PDFKit
import UIKit

final class CVPreviewViewController: UIViewController {

    private let pdfURL: URL

    private lazy var pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = AppTheme.background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(pdfURL: URL) {
        self.pdfURL = pdfURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = "CV Preview"
        setupNavigationBar()
        setupUI()
        loadPDF()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Share CV"
    }

    private func setupUI() {
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadPDF() {
        pdfView.document = PDFDocument(url: pdfURL)
    }

    @objc private func shareTapped() {
        let activityViewController = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true)
    }
}
