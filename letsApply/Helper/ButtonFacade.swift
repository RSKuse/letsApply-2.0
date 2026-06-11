//
//  ButtonFacade.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import Foundation
import UIKit

class ButtonFacade {
    static let shared = ButtonFacade()

    private init() {} // Singleton

    /// Generic method to configure a UIButton
    func createButton(
        title: String,
        titleColor: UIColor = .white,
        backgroundColor: UIColor = .systemBlue,
        font: UIFont = .systemFont(ofSize: 16, weight: .bold),
        cornerRadius: CGFloat = 25,
        target: Any?,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.backgroundColor = backgroundColor
        button.titleLabel?.font = font
        button.layer.cornerRadius = cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    /// Method to apply common design updates
    func applyDesign(to button: UIButton, cornerRadius: CGFloat = 10, shadow: Bool = true) {
        button.layer.cornerRadius = cornerRadius
        if shadow {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.2
            button.layer.shadowOffset = CGSize(width: 2, height: 2)
            button.layer.shadowRadius = 5
        }
    }
}
