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
        
        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let url = url else {
                    completion(.failure(NSError(
                        domain: "URLGenerationError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not generate image URL."]
                    )))
                    return
                }
                
                completion(.success(url.absoluteString))
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



/*import Foundation
import FirebaseStorage

class ProfilePictureService {
    static let shared = ProfilePictureService()
    private init() {}

    func uploadProfilePicture(uid: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
            return
        }

        let storageRef = Storage.storage().reference().child("profile_pictures/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let url = url else {
                    completion(.failure(NSError(domain: "URLGenerationError", code: -1, userInfo: nil)))
                    return
                }
                completion(.success(url.absoluteString))
            }
        }
    }

    func fetchProfilePicture(urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
 }*/
