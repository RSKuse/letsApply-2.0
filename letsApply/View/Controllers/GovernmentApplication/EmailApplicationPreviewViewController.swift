//
//  EmailApplicationPreviewViewController.swift
//  letsApply
//

import UIKit

final class EmailApplicationPreviewViewController: UIViewController {

    private let recipient: String
    private let subjectText: String
    private let bodyText: String
    private let attachmentURLs: [URL]

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(
        recipient: String,
        subject: String,
        body: String,
        attachmentURLs: [URL]
    ) {
        self.recipient = recipient
        self.subjectText = subject
        self.bodyText = body
        self.attachmentURLs = attachmentURLs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Email Preview"
        view.backgroundColor = AppTheme.background
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Share email documents"
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(makeHeaderCard())
        contentStackView.addArrangedSubview(makeMessageCard())
        contentStackView.addArrangedSubview(makeAttachmentsCard())

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func makeHeaderCard() -> UIView {
        let card = makeCard()
        let title = makeLabel(
            text: "Prepared Email",
            font: .systemFont(ofSize: 20, weight: .bold),
            color: .label
        )
        let recipientLabel = makeLabel(
            text: "To\n\(recipient.isEmpty ? "Recruiter email missing" : recipient)",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: recipient.isEmpty ? .systemRed : AppTheme.secondaryText,
            lines: 0
        )
        let subjectLabel = makeLabel(
            text: "Subject\n\(subjectText)",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: AppTheme.secondaryText,
            lines: 0
        )
        let copyButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = "Copy Recipient and Message"
        configuration.image = UIImage(systemName: "doc.on.doc")
        configuration.imagePadding = 8
        configuration.baseForegroundColor = AppTheme.brand
        copyButton.configuration = configuration
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

        pin(stack([title, recipientLabel, subjectLabel, copyButton]), to: card)
        return card
    }

    private func makeMessageCard() -> UIView {
        let card = makeCard()
        let title = makeLabel(
            text: "Email Message",
            font: .systemFont(ofSize: 18, weight: .bold),
            color: .label
        )
        let textView = UITextView()
        textView.text = bodyText
        textView.font = .systemFont(ofSize: 15, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = AppTheme.background
        textView.isEditable = false
        textView.layer.cornerRadius = AppTheme.cardRadius
        textView.layer.borderColor = AppTheme.border.cgColor
        textView.layer.borderWidth = 1
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: 280).isActive = true

        pin(stack([title, textView]), to: card)
        return card
    }

    private func makeAttachmentsCard() -> UIView {
        let card = makeCard()
        let title = makeLabel(
            text: "Attachments",
            font: .systemFont(ofSize: 18, weight: .bold),
            color: .label
        )
        let rows = attachmentURLs.map { url -> UIView in
            let icon = UIImageView(image: UIImage(systemName: "doc.fill"))
            icon.tintColor = AppTheme.brand
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 28).isActive = true

            let label = makeLabel(
                text: url.lastPathComponent,
                font: .systemFont(ofSize: 14, weight: .semibold),
                color: .label,
                lines: 0
            )
            let row = UIStackView(arrangedSubviews: [icon, label])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            return row
        }
        let note = makeLabel(
            text: "Simulator cannot send through Apple Mail. This preview proves the recipient, subject, message, and generated attachments. Test the final Send action on a physical iPhone with a Mail account configured.",
            font: .systemFont(ofSize: 13, weight: .medium),
            color: AppTheme.secondaryText,
            lines: 0
        )
        pin(stack([title] + rows + [note]), to: card)
        return card
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = """
        To: \(recipient)
        Subject: \(subjectText)

        \(bodyText)
        """
        let alert = UIAlertController(
            title: "Email Copied",
            message: "The recipient, subject, and message are ready to paste into another email app.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func shareTapped() {
        let controller = UIActivityViewController(
            activityItems: attachmentURLs,
            applicationActivities: nil
        )
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(controller, animated: true)
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = AppTheme.surface
        view.layer.cornerRadius = AppTheme.cardRadius
        view.layer.borderColor = AppTheme.border.cgColor
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func stack(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func pin(_ stack: UIStackView, to card: UIView) {
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func makeLabel(
        text: String,
        font: UIFont,
        color: UIColor,
        lines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
