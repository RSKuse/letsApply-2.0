//
//  SignUpViewController.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/10.
//

import Foundation
import UIKit

class SignUpViewController: UIViewController {
    
    lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your name"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your email"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your password"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [nameTextField, emailTextField, passwordTextField, signUpButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func signUpTapped() {
        let viewModel = SignUpViewModel()
        viewModel.createUser(
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            location: "Johannesburg",
            jobTitle: "iOS Developer",
            skills: "Swift, UIKit",
            qualifications: "BSc Computer Science",
            experience: "2 years",
            education: "University of XYZ"
        ) { error in
            if let error = error {
                print("Sign up failed: \(error.localizedDescription)")
            } else {
                print("User created successfully!")
            }
        }
    }
}
