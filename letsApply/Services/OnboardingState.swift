//
//  OnboardingState.swift
//  letsApply
//

import Foundation

enum OnboardingState {

    private static let completedKey = "hasCompletedOnboarding"

    static var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: completedKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    static func reset() {
        UserDefaults.standard.set(false, forKey: completedKey)
    }
}
