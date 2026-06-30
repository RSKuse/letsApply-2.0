//
//  SignInViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/11.
//

import Foundation
class SignInViewModel {
    let firebaseAuthService: FirebaseAuthenticationService

    init(firebaseAuthService: FirebaseAuthenticationService = .shared) {
        self.firebaseAuthService = firebaseAuthService
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        firebaseAuthService.signIn(email: email, password: password, completion: completion)
    }

    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        firebaseAuthService.resetPassword(email: email, completion: completion)
    }
}
    
    
    
