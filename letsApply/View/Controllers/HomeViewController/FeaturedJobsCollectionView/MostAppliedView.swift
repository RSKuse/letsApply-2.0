//
//  MostAppliedView.swift
//  letsApply
//

import UIKit

class MostAppliedView: UIView {

    private lazy var mostAppliedLabel: UILabel = {
        let label = UILabel()
        label.text = "Featured"
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGreen
        layer.cornerRadius = 6
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        setupUI()
    }

    private func setupUI() {
        addSubview(mostAppliedLabel)

        NSLayoutConstraint.activate([
            mostAppliedLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            mostAppliedLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            mostAppliedLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
