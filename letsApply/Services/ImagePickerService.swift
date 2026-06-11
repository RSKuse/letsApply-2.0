//
//  ImagePickerService.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import UIKit

protocol ImagePickerDelegate: AnyObject {
    func didSelectImage(_ image: UIImage)
}

class ImagePickerService: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: ImagePickerDelegate?
    
    func presentImagePicker(from viewController: UIViewController) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        viewController.present(imagePicker, animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let selectedImage = info[.originalImage] as? UIImage {
            delegate?.didSelectImage(selectedImage)
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

/*import Foundation
import UIKit

protocol ImagePickerDelegate: AnyObject {
    func didSelectImage(_ image: UIImage)
}

class ImagePickerService: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var delegate: ImagePickerDelegate?

    func presentImagePicker(from viewController: UIViewController) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        viewController.present(imagePicker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            delegate?.didSelectImage(selectedImage)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
 }*/
