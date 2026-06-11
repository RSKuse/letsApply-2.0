//
//  ProfileViewController.swift
//  letsApply
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileImageView, nameTextField, emailTextField, locationTextField, skillsTextField, saveButton, logoutButton])
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var nameTextField = makeTextField(placeholder: "Name")
    private lazy var emailTextField = makeTextField(placeholder: "Email")
    private lazy var locationTextField = makeTextField(placeholder: "Location")
    private lazy var skillsTextField = makeTextField(placeholder: "Skills comma separated")

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .white
        setupUI()
        fetchProfileData()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .words
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return textField
    }

    private func fetchProfileData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            nameTextField.text = "Guest User"
            emailTextField.text = ""
            locationTextField.text = "South Africa"
            skillsTextField.text = "Swift, UIKit, Firebase"
            return
        }

        FirestoreService().fetchUserProfile(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.nameTextField.text = profile.name
                    self?.emailTextField.text = profile.email
                    self?.locationTextField.text = profile.location
                    self?.skillsTextField.text = profile.skills.joined(separator: ", ")
                case .failure(let error):
                    print("Error fetching profile: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func saveProfile() {
        let skills = (skillsTextField.text ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let profile = UserProfile(
            uid: Auth.auth().currentUser?.uid ?? UUID().uuidString,
            name: nameTextField.text ?? "Guest User",
            email: emailTextField.text ?? "",
            location: locationTextField.text ?? "South Africa",
            profilePictureUrl: nil,
            jobTitle: "",
            skills: skills,
            qualifications: [],
            experience: "",
            education: ""
        )

        FirestoreService().saveUserProfile(profile) { [weak self] error in
            DispatchQueue.main.async {
                let title = error == nil ? "Saved" : "Error"
                let message = error?.localizedDescription ?? "Your profile has been updated."
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    @objc private func logout() {
        FirebaseAuthenticationService.shared.signOut { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    let alert = UIAlertController(title: "Logout Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                } else {
                    self?.tabBarController?.selectedIndex = 0
                }
            }
        }
    }
}
