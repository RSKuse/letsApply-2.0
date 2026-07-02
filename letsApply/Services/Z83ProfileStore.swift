//
//  Z83ProfileStore.swift
//  letsApply
//

import Foundation
import Security

final class Z83ProfileStore {

    enum StoreError: LocalizedError {
        case encodingFailed
        case keychain(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "The Z83 profile could not be prepared for secure storage."
            case .keychain(let status):
                return "The secure Z83 profile could not be saved. Keychain status: \(status)."
            }
        }
    }

    private let service = "com.simphiwe.letsApply.z83"

    func load(userId: String) -> Z83ApplicationProfile? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let profile = try? JSONDecoder().decode(Z83ApplicationProfile.self, from: data) {
            return profile
        }

        guard let data = try? Data(contentsOf: fallbackURL(userId: userId)) else {
            return nil
        }
        return try? JSONDecoder().decode(Z83ApplicationProfile.self, from: data)
    }

    func save(_ profile: Z83ApplicationProfile, userId: String) throws {
        guard let data = try? JSONEncoder().encode(profile) else {
            throw StoreError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            try saveProtectedFallback(data, userId: userId)
            return
        }

        var createQuery = query
        attributes.forEach { createQuery[$0.key] = $0.value }
        let addStatus = SecItemAdd(createQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            try saveProtectedFallback(data, userId: userId)
            return
        }
    }

    private func saveProtectedFallback(_ data: Data, userId: String) throws {
        let url = fallbackURL(userId: userId)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func fallbackURL(userId: String) -> URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let safeUserId = userId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return directory
            .appendingPathComponent("SecureZ83", isDirectory: true)
            .appendingPathComponent("\(safeUserId).json")
    }
}
