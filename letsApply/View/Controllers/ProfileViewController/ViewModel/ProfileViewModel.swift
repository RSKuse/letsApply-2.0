//
//  ProfileViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2025/01/12.
//

import Foundation
import UIKit
import FirebaseAuth

class ProfileViewModel {
    
    private let firestoreService = FirestoreService()
    
    func fetchUserProfile(completion: @escaping (UserProfile) -> Void) {
        guard let userUID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        firestoreService.fetchUserProfile(uid: userUID) { result in
            switch result {
            case .success(let profile):
                completion(profile)
            case .failure(let error):
                print("Error fetching profile: \(error.localizedDescription)")
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        firestoreService.saveUserProfile(profile) { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
            } else {
                print("Profile saved successfully!")
            }
        }
    }
}
