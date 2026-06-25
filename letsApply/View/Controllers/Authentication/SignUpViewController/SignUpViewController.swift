//
//  SignUpViewController.swift
//  letsApply
//

import UIKit

class SignUpViewController: UIViewController {

    private let firestoreService = FirestoreService()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create your profile"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Register now, then complete your career profile before applying."
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var nameTextField = makeTextField(placeholder: "Full name")
    private lazy var emailTextField = makeTextField(placeholder: "Email", keyboardType: .emailAddress)
    private lazy var passwordTextField = makeTextField(placeholder: "Password", isSecure: true)

    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Already have an account? Sign In", for: .normal)
        button.setTitleColor(.systemGreen, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            nameTextField,
            emailTextField,
            passwordTextField,
            signUpButton,
            signInButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Register"
        setupUI()
    }

    private func setupUI() {
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            signUpButton.heightAnchor.constraint(equalToConstant: 52),
            signInButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeTextField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> UITextField {
        let textField = UITextField()
        textField.configureTextField(placeholder: placeholder, keyboardType: keyboardType, isSecure: isSecure)
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.layer.borderWidth = 1
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }

    @objc private func signUpTapped() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Missing Details", message: "Please enter your name, email, and password.")
            return
        }

        signUpButton.isEnabled = false

        FirebaseAuthenticationService.shared.signUp(email: email, password: password) { [weak self] error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.signUpButton.isEnabled = true
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                }
                return
            }

            guard let uid = FirebaseAuthenticationService.shared.currentUserId else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Sign Up Failed", message: "We could not read your user ID.")
                }
                return
            }

            let profile = UserProfile(
                uid: uid,
                name: name,
                email: email,
                location: "",
                profilePictureUrl: nil,
                jobTitle: "",
                skills: [],
                qualifications: [],
                experience: "",
                education: "",
                savedJobs: [],
                isPremium: false
            )

            self.firestoreService.saveUserProfile(profile) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showAlert(title: "Profile Save Failed", message: error.localizedDescription)
                    } else {
                        AppRouter.showProfileSetup()
                    }
                }
            }
        }
    }

    @objc private func signInTapped() {
        navigationController?.pushViewController(SignInViewController(), animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
