//
//  UITextField+Extensions..swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/11.
//

import Foundation
import UIKit

extension UITextField {
    func configureTextField(placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isSecureTextEntry = isSecure
        self.endEditing(true)
        self.borderStyle = .roundedRect
        self.autocapitalizationType = .none
        self.returnKeyType = .done
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
