//
//  SignUpViewController+Spinner.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/24.
//

import Foundation
import UIKit

extension SignUpViewController {
    func showLoadingSpinner() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.tag = 999 // Unique tag to identify the spinner
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)
    }

    func hideLoadingSpinner() {
        if let spinner = view.viewWithTag(999) as? UIActivityIndicatorView {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
        }
    }
}
