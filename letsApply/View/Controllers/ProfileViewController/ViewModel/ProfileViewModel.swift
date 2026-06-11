//
//  ProfileViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2025/01/12.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel {
    
    private let db = Firestore.firestore()
    
    
    func fetchUserProfile(completion: @escaping (UserProfile) -> Void) {
        guard let userUID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        FirestoreService().fetchUserProfile(uid: userUID) { result in
            switch result {
            case .success(let profile):
                completion(profile)
            case .failure(let error):
                print("Error fetching profile: \(error.localizedDescription)")
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        guard let userUID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "name": profile.name,
            "email": profile.email,
            "skills": profile.skills,
            "location": profile.location
        ]
        
        db.collection("users").document(userUID).setData(data) { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
            } else {
                print("Profile saved successfully!")
            }
        }
    }
}
