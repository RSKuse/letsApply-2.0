//
//  CVBuilderViewController.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import Foundation
import UIKit

class CVBuilderViewController: UIViewController {
    override func viewDidLoad() {
       super.viewDidLoad()
       view.backgroundColor = .white
        title = "CV Builder"

        let label = UILabel()
        label.text = "CV Builder Coming Soon!"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
