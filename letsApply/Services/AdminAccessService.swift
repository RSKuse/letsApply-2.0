//
//  AdminAccessService.swift
//  letsApply
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AdminAccessService {

    private let db = Firestore.firestore()

    func checkAccess(completion: @escaping (Result<Bool, Error>) -> Void) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LETSAPPLY_DEBUG_ADMIN"] == "1" {
            completion(.success(true))
            return
        }
        #endif

        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            completion(.success(false))
            return
        }

        db.collection("admins")
            .document(user.uid)
            .getDocument { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let isAdmin = snapshot?.exists == true
                    && snapshot?.data()?["active"] as? Bool == true
                completion(.success(isAdmin))
            }
    }
}
