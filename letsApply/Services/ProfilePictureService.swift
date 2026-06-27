//
//  ProfilePictureService.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import Foundation
import UIKit
import FirebaseStorage

class ProfilePictureService {
    
    static let shared = ProfilePictureService()
    
    private init() {}
    
    func uploadProfilePicture(uid: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(
                domain: "ImageError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid image data."]
            )))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.fetchDownloadURLWithRetry(reference: storageRef, attemptsRemaining: 3, completion: completion)
        }
    }

    private func fetchDownloadURLWithRetry(
        reference: StorageReference,
        attemptsRemaining: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        reference.downloadURL { url, error in
            if let url = url {
                completion(.success(url.absoluteString))
                return
            }

            guard attemptsRemaining > 0 else {
                completion(.failure(NSError(
                    domain: "URLGenerationError",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Firebase Storage did not return the uploaded photo URL. Check Storage rules and try again. \(error?.localizedDescription ?? "")"
                    ]
                )))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.fetchDownloadURLWithRetry(
                    reference: reference,
                    attemptsRemaining: attemptsRemaining - 1,
                    completion: completion
                )
            }
        }
    }
    
    func fetchProfilePicture(urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data, let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                
                completion(image)
            }
        }.resume()
    }
}
