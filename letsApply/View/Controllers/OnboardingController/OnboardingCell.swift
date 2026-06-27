//
//  OnboardingCell.swift
//  letsApply
//

import UIKit

class OnboardingCell: UICollectionViewCell {

    private lazy var visualPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.ink
        view.layer.cornerRadius = AppTheme.cardRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.brandBright
        view.layer.cornerRadius = AppTheme.cardRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = AppTheme.ink
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var metricLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = AppTheme.cyan
        label.textAlignment = .right
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var panelTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Career intelligence, ready when you are."
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var panelStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "PROFILE  |  MATCH  |  REVIEW"
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.62)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = AppTheme.brand
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(visualPanelView)
        visualPanelView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        visualPanelView.addSubview(metricLabel)
        visualPanelView.addSubview(panelTitleLabel)
        visualPanelView.addSubview(panelStatusLabel)
        contentView.addSubview(eyebrowLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            visualPanelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            visualPanelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            visualPanelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            visualPanelView.heightAnchor.constraint(equalToConstant: 176),

            iconContainerView.topAnchor.constraint(equalTo: visualPanelView.topAnchor, constant: 18),
            iconContainerView.leadingAnchor.constraint(equalTo: visualPanelView.leadingAnchor, constant: 18),
            iconContainerView.widthAnchor.constraint(equalToConstant: 52),
            iconContainerView.heightAnchor.constraint(equalToConstant: 52),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),

            metricLabel.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            metricLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 12),
            metricLabel.trailingAnchor.constraint(equalTo: visualPanelView.trailingAnchor, constant: -18),

            panelTitleLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 20),
            panelTitleLabel.leadingAnchor.constraint(equalTo: iconContainerView.leadingAnchor),
            panelTitleLabel.trailingAnchor.constraint(equalTo: visualPanelView.trailingAnchor, constant: -18),

            panelStatusLabel.leadingAnchor.constraint(equalTo: panelTitleLabel.leadingAnchor),
            panelStatusLabel.trailingAnchor.constraint(equalTo: panelTitleLabel.trailingAnchor),
            panelStatusLabel.bottomAnchor.constraint(equalTo: visualPanelView.bottomAnchor, constant: -18),

            eyebrowLabel.topAnchor.constraint(equalTo: visualPanelView.bottomAnchor, constant: 28),
            eyebrowLabel.leadingAnchor.constraint(equalTo: visualPanelView.leadingAnchor),
            eyebrowLabel.trailingAnchor.constraint(equalTo: visualPanelView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: eyebrowLabel.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: eyebrowLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: eyebrowLabel.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(
        eyebrow: String,
        title: String,
        description: String,
        metric: String,
        systemImageName: String
    ) {
        eyebrowLabel.text = eyebrow
        titleLabel.text = title
        descriptionLabel.text = description
        metricLabel.text = metric
        iconImageView.image = UIImage(systemName: systemImageName)
    }
}
