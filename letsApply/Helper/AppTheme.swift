//
//  AppTheme.swift
//  letsApply
//

import UIKit

enum AppTheme {

    static let brand = UIColor(red: 0.05, green: 0.48, blue: 0.32, alpha: 1)
    static let brandBright = UIColor(red: 0.10, green: 0.76, blue: 0.45, alpha: 1)
    static let cyan = UIColor(red: 0.19, green: 0.69, blue: 0.76, alpha: 1)
    static let amber = UIColor(red: 0.96, green: 0.67, blue: 0.20, alpha: 1)
    static let ink = UIColor(red: 0.05, green: 0.10, blue: 0.13, alpha: 1)

    static let background = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.07, blue: 0.08, alpha: 1)
            : UIColor(red: 0.96, green: 0.98, blue: 0.97, alpha: 1)
    }

    static let surface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1)
            : .white
    }

    static let mutedSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.16, blue: 0.17, alpha: 1)
            : UIColor(red: 0.91, green: 0.95, blue: 0.93, alpha: 1)
    }

    static let border = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.83, green: 0.88, blue: 0.85, alpha: 1)
    }

    static let secondaryText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.66)
            : UIColor(red: 0.33, green: 0.39, blue: 0.39, alpha: 1)
    }

    static let cardRadius: CGFloat = 8

    static func configureGlobalAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = background
        navigationAppearance.shadowColor = .clear
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = brand

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = surface
        tabAppearance.shadowColor = border

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: brand,
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: secondaryText,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        [
            tabAppearance.stackedLayoutAppearance,
            tabAppearance.inlineLayoutAppearance,
            tabAppearance.compactInlineLayoutAppearance
        ].forEach { itemAppearance in
            itemAppearance.selected.iconColor = brand
            itemAppearance.selected.titleTextAttributes = selectedAttributes
            itemAppearance.normal.iconColor = secondaryText
            itemAppearance.normal.titleTextAttributes = normalAttributes
        }

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    static func primaryButtonConfiguration(
        title: String,
        systemImageName: String? = nil
    ) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = brand
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 15,
            leading: 18,
            bottom: 15,
            trailing: 18
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            return updatedAttributes
        }

        if let systemImageName {
            configuration.image = UIImage(systemName: systemImageName)
            configuration.imagePlacement = .trailing
            configuration.imagePadding = 10
        }

        return configuration
    }
}
