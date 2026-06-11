//
//  AdvertCell.swift
//  letsApply
//

import UIKit

class AdvertCell: UICollectionViewCell {

    static let reuseIdentifier = "AdvertCellID"

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "advert_banner") ?? UIImage(systemName: "briefcase.fill")
        imageView.tintColor = .white
        imageView.layer.cornerRadius = 20
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemGreen
        return imageView
    }()

    lazy var overlayLabel: UILabel = {
        let label = UILabel()
        label.text = "Find work that fits your future"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.addSubview(overlayLabel)

        NSLayoutConstraint.activate([
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayLabel.leftAnchor.constraint(equalTo: imageView.leftAnchor, constant: 18),
            overlayLabel.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: -18),
            overlayLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
