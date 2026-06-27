//
//  AdvertCell.swift
//  letsApply
//

import UIKit

class AdvertCell: UICollectionViewCell {

    static let reuseIdentifier = "AdvertCellID"

    private lazy var bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.ink
        view.layer.cornerRadius = AppTheme.cardRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var eyebrowLabel: UILabel = {
        let label = UILabel()
        label.text = "CAREER COMMAND CENTRE"
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = AppTheme.cyan
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Move from discovery\nto application"
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Live jobs connected  |  Review before submit"
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.66)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var signalIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "scope"))
        imageView.tintColor = AppTheme.brandBright
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

    private func setupUI() {
        contentView.addSubview(bannerView)
        bannerView.addSubview(eyebrowLabel)
        bannerView.addSubview(titleLabel)
        bannerView.addSubview(subtitleLabel)
        bannerView.addSubview(signalIconView)

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            eyebrowLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 18),
            eyebrowLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 18),
            eyebrowLabel.trailingAnchor.constraint(equalTo: signalIconView.leadingAnchor, constant: -12),

            signalIconView.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 18),
            signalIconView.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -18),
            signalIconView.widthAnchor.constraint(equalToConstant: 34),
            signalIconView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -72),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -18),
            subtitleLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -18)
        ])
    }
}
