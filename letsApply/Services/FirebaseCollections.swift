//
//  FirebaseCollections.swift
//  letsApply
//
//  Created by Gugulethu Mhlanga on 2024/11/19.
//

import Foundation

enum FirebaseCollections: String {
    case users
    case jobs
    case applications
    case savedJobs
}

enum AppFeatures {
    static let firebaseStorageUploadsEnabled = false

    static let storagePausedMessage = "PDF and photo uploads need Firebase Storage, which requires the paid Blaze plan. For now, Let's Apply will use your profile and CV draft so you can keep building and testing without paying."
}
