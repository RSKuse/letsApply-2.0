//
//  FirebaseAuthenticationService.swift
//  letsApply
//

import Foundation
import FirebaseAuth

class FirebaseAuthenticationService {

    static let shared = FirebaseAuthenticationService()

    private init() {}

    var isAuthenticatedAnonymously: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }

    var isAuthenticatedViaEmail: Bool {
        return Auth.auth().currentUser?.email != nil
    }

    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }

    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String {
        return Auth.auth().currentUser?.email ?? ""
    }

    func signUpAnonymously(completion: @escaping (Error?) -> Void) {
        if Auth.auth().currentUser?.isAnonymous == true {
            completion(nil)
            return
        }

        Auth.auth().signInAnonymously { _, error in
            completion(error)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            currentUser.link(with: credential) { _, error in
                completion(error)
            }
        } else {
            Auth.auth().createUser(withEmail: email, password: password) { _, error in
                completion(error)
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(NSError(
                    domain: "AuthError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User not found."]
                )))
                return
            }

            FirestoreService().fetchUserProfile(uid: user.uid) { result in
                switch result {
                case .success(var profile):
                    if profile.email.isEmpty {
                        profile.email = user.email ?? email
                    }
                    if profile.name == "Guest User", !user.isAnonymous {
                        profile.name = ""
                        profile.location = ""
                        profile.skills = []
                    }
                    completion(.success(profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }

    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(nil)
        } catch {
            completion(error)
        }
    }

    static func userMessage(for error: Error) -> String {
        let errorCode = AuthErrorCode(rawValue: (error as NSError).code)

        switch errorCode {
        case .keychainError:
            return "Secure sign-in storage is unavailable. Stop the app and run it again from Xcode. You do not need to delete your Firebase account."
        case .emailAlreadyInUse, .credentialAlreadyInUse:
            return "An account already exists for this email. Use Sign In instead of creating another profile."
        case .invalidCredential, .wrongPassword, .userNotFound:
            return "The email or password is incorrect. Try again or reset your password."
        case .invalidEmail:
            return "Enter a valid email address."
        case .weakPassword:
            return "Use a stronger password with at least six characters."
        case .networkError:
            return "The network connection was interrupted. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts were made. Wait a moment, then try again."
        case .operationNotAllowed:
            return "This sign-in method is not enabled in Firebase Authentication."
        default:
            return error.localizedDescription
        }
    }
}
