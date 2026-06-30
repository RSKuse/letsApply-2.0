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

    static let storagePausedMessage = "PDF uploads are paused. Let’s Apply creates CV and cover-letter PDFs locally so you can preview, save, and share them without paid cloud storage."
}
