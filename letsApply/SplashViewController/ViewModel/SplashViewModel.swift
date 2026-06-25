//
//  SplashScreenViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/25.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
    case onboarding
    case profileSetup
    case mainApp
}

class SplashViewModel {
    
    func checkAuthentication(completion: @escaping (AuthenticationState) -> Void) {
        
        guard let user = Auth.auth().currentUser else {
            completion(.onboarding)
            return
        }

        if user.isAnonymous {
            completion(.mainApp)
            return
        }

        FirestoreService().fetchUserProfile(uid: user.uid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    completion(profile.isComplete ? .mainApp : .profileSetup)
                case .failure:
                    completion(.profileSetup)
                }
            }
        }
    }
}
