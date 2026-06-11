//
//  SecurityManager.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/11/24.
//

import Foundation
import UIKit

class SecurityManager {
    static let shared = SecurityManager()

    func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Skip jailbreak check on the Simulator
        return false
        #else
        // Check for known jailbreak files
        let paths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                print("Detected possible jailbreak file at path: \(path)")
                return true
            }
        }

        // Check if sandbox is accessible
        if canWriteToRestrictedPath() {
            print("Detected sandbox violation.")
            return true
        }

        // Check for suspicious URL schemes (e.g., Cydia)
        if let url = URL(string: "cydia://"), UIApplication.shared.canOpenURL(url) {
            print("Detected Cydia URL scheme.")
            return true
        }

        return false
        #endif
    }

    private func canWriteToRestrictedPath() -> Bool {
        let path = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
}
