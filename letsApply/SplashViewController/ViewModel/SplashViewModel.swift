//
//  SplashScreenViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/25.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
    case signUp
    case profileSetup
    case joblistingScreen
}

class SplashViewModel {
    
    func checkAuthentication(completion: @escaping (AuthenticationState) -> Void) {
        
        guard let user = Auth.auth().currentUser else {
            return completion(.signUp)
        }
        
        // Fetch user profile to determine next screen
        FirestoreService().fetchUserProfile(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let profile):
                    if profile.skills.isEmpty || profile.location.isEmpty {
                        // Show ProfileSetupViewController if profile is incomplete
                        completion(.profileSetup)
                    } else {
                        // Show MainTabBarController if profile is complete
                        completion(.joblistingScreen)
                    }
                case .failure:
                    // Default to SignInViewController on error
                    completion(.signUp)
                }
            }
            
        }
    }
}
