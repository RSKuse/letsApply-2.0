//
//  ValidationManager.swift
//  letsApply
//
//  Created by Gugulethu Mhlanga on 2024/11/19.
//

import Foundation

class ValidationManager {
    
    static var shared = ValidationManager()
    
    /**
     Validate an Email
     */
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /**
     Validate Password
     */
    func validatePassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*])[A-Za-z0-9!@#$%^&*]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }

    /**
     Validate Input Fields
     */
    func validateInputs(fields: [String]) -> Bool {
        return !fields.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

extension ValidationManager {
    func validateFields(_ fields: [String: String?]) -> (isValid: Bool, message: String?) {
        for (key, value) in fields {
            if let value = value, value.isEmpty {
                return (false, "\(key) is required.")
            }
        }
        return (true, nil)
    }
}
