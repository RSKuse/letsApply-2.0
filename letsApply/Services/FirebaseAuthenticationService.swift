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

            FirestoreService().fetchUserProfile(uid: user.uid, completion: completion)
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
}
