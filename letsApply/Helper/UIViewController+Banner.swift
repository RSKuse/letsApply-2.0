//
//  UIViewController+Banner.swift
//  letsApply
//

import UIKit

extension UIViewController {

    func showBanner(
        message: String,
        style: BannerStyle = .info,
        duration: TimeInterval = 3.0
    ) {
        view.subviews
            .compactMap { $0 as? BannerView }
            .forEach { $0.removeFromSuperview() }

        let banner = BannerView(message: message, style: style)
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: -12)
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.4
        ) {
            banner.alpha = 1
            banner.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.25, animations: {
                banner.alpha = 0
                banner.transform = CGAffineTransform(translationX: 0, y: -8)
            }, completion: { _ in
                banner.removeFromSuperview()
            })
        }
    }
}

enum BannerStyle {
    case info
    case success
    case error

    var backgroundColor: UIColor {
        switch self {
        case .info:
            return AppTheme.ink
        case .success:
            return AppTheme.brand
        case .error:
            return UIColor(red: 0.78, green: 0.22, blue: 0.22, alpha: 1)
        }
    }

    var iconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

private final class BannerView: UIView {

    init(message: String, style: BannerStyle) {
        super.init(frame: .zero)

        backgroundColor = style.backgroundColor
        layer.cornerRadius = AppTheme.cardRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        let iconView = UIImageView(image: UIImage(systemName: style.iconName))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
