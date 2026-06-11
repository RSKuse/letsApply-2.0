//
//  SignInViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/11.
//

import Foundation
import FirebaseAuth

class SignInViewModel {
    let firebaseAuthService: FirebaseAuthenticationService
    let firestoreService: FirestoreService

    init(firebaseAuthService: FirebaseAuthenticationService = .shared,
         firestoreService: FirestoreService = FirestoreService()) {
        self.firebaseAuthService = firebaseAuthService
        self.firestoreService = firestoreService
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        firebaseAuthService.signIn(email: email, password: password) { [weak self] result in
            switch result {
            case .success:
                guard let userId = Auth.auth().currentUser?.uid else {
                    completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found."])))
                    return
                }
                // Fetch user profile
                self?.firestoreService.fetchUserProfile(uid: userId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        firebaseAuthService.resetPassword(email: email, completion: completion)
    }
}
    
    
    
