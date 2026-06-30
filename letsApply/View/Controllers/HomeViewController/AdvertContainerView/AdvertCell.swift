//
//  AdvertCell.swift
//  letsApply
//

import UIKit

struct CareerInsight {
    let category: String
    let title: String
    let detail: String
    let systemImageName: String
    let style: CareerInsightStyle
}

enum CareerInsightStyle {
    case ink
    case green
    case warm
    case ocean

    var backgroundColor: UIColor {
        switch self {
        case .ink:
            return AppTheme.ink
        case .green:
            return AppTheme.brand
        case .warm:
            return UIColor(red: 0.96, green: 0.91, blue: 0.78, alpha: 1)
        case .ocean:
            return UIColor(red: 0.08, green: 0.31, blue: 0.41, alpha: 1)
        }
    }

    var primaryTextColor: UIColor {
        switch self {
        case .warm:
            return AppTheme.ink
        default:
            return .white
        }
    }

    var accentColor: UIColor {
        switch self {
        case .ink:
            return AppTheme.cyan
        case .green:
            return AppTheme.amber
        case .warm:
            return AppTheme.brand
        case .ocean:
            return AppTheme.brandBright
        }
    }

    var secondaryTextColor: UIColor {
        primaryTextColor.withAlphaComponent(0.72)
    }
}

class AdvertCell: UICollectionViewCell {

    static let reuseIdentifier = "AdvertCellID"

    private lazy var bannerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = AppTheme.cardRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var interactionLabel: UILabel = {
        let label = UILabel()
        label.text = "SWIPE OR TAP FOR THE NEXT INSIGHT"
        label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var signalIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with insight: CareerInsight) {
        bannerView.backgroundColor = insight.style.backgroundColor
        eyebrowLabel.text = insight.category.uppercased()
        eyebrowLabel.textColor = insight.style.accentColor
        titleLabel.text = insight.title
        titleLabel.textColor = insight.style.primaryTextColor
        subtitleLabel.text = insight.detail
        subtitleLabel.textColor = insight.style.secondaryTextColor
        interactionLabel.textColor = insight.style.secondaryTextColor
        signalIconView.image = UIImage(systemName: insight.systemImageName)
        signalIconView.tintColor = insight.style.accentColor
    }

    private func setupUI() {
        contentView.addSubview(bannerView)
        bannerView.addSubview(eyebrowLabel)
        bannerView.addSubview(titleLabel)
        bannerView.addSubview(subtitleLabel)
        bannerView.addSubview(interactionLabel)
        bannerView.addSubview(signalIconView)

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            eyebrowLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 16),
            eyebrowLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 18),
            eyebrowLabel.trailingAnchor.constraint(equalTo: signalIconView.leadingAnchor, constant: -12),

            signalIconView.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 16),
            signalIconView.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -18),
            signalIconView.widthAnchor.constraint(equalToConstant: 32),
            signalIconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: eyebrowLabel.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: eyebrowLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -64),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -18),

            interactionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            interactionLabel.trailingAnchor.constraint(equalTo: subtitleLabel.trailingAnchor),
            interactionLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -14)
        ])
    }
}
