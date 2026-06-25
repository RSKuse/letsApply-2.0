//
//  AdvertCell.swift
//  letsApply
//

import UIKit

class AdvertCell: UICollectionViewCell {

    static let reuseIdentifier = "AdvertCellID"

    private lazy var bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "advert_banner")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 22
        imageView.backgroundColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Apply smarter"
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Find jobs, build your profile, and track every opportunity."
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
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
        contentView.addSubview(bannerImageView)
        contentView.addSubview(overlayView)
        overlayView.addSubview(titleLabel)
        overlayView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bannerImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: bannerImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: bannerImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bannerImageView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -20)
        ])
    }
}
