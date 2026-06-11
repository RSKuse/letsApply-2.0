//
//  SignUpViewModel.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/11.


import Foundation
import FirebaseAuth

class SignUpViewModel {
    
    private let firebaseAuthService: FirebaseAuthenticationService
    private let firestoreService: FirestoreService
    
    init(firebaseAuthService: FirebaseAuthenticationService = .shared,
         firestoreService: FirestoreService = FirestoreService()) {
        self.firebaseAuthService = firebaseAuthService
        self.firestoreService = firestoreService
    }
    
    func createUser(name: String,
                    email: String,
                    password: String,
                    location: String,
                    jobTitle: String,
                    skills: String,
                    qualifications: String,
                    experience: String,
                    education: String,
                    completion: @escaping (Error?) -> Void) {
        
        // ✅ Basic validation
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !location.isEmpty,
              !jobTitle.isEmpty, !skills.isEmpty, !qualifications.isEmpty,
              !experience.isEmpty, !education.isEmpty else {
            completion(NSError(domain: "ValidationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "All fields are required."]))
            return
        }
        
        // ✅ Create user in Firebase Auth
        firebaseAuthService.signUp(email: email, password: password) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            // ✅ Get the current user's UID
            guard let uid = Auth.auth().currentUser?.uid else {
                completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found after sign-up."]))
                return
            }
            
            // ✅ Create a UserProfile object
            let profile = UserProfile(
                uid: uid,
                name: name,
                email: email,
                location: location,
                profilePictureUrl: nil,
                jobTitle: jobTitle,
                skills: skills.components(separatedBy: ", "),
                qualifications: qualifications.components(separatedBy: ", "),
                experience: experience,
                education: education
            )
            
            // ✅ Save the profile to Firestore
            self.firestoreService.saveUserProfile(profile, completion: completion)
        }
    }
}
