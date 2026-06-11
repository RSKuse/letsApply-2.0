//
//  FirestoreServiceTests.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

//import Foundation
//import XCTest
//import FirebaseStorage
//@testable import letsApply
//
//class FirestoreServiceTests: XCTestCase {
//    var firestoreService: FirestoreService!
//
//    override func setUp() {
//        super.setUp()
//        firestoreService = FirestoreService()
//    }
//
//    func testUploadProfileImage() {
//        let dummyImage = UIImage(named: "dummyImage")!
//        let dummyUID = "testUser123"
//
//        let expectation = self.expectation(description: "Image upload should succeed")
//
//        firestoreService.uploadProfileImage(uid: dummyUID, image: dummyImage) { result in
//            switch result {
//            case .success(let url):
//                XCTAssertTrue(url.contains("profile_pictures"))
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Image upload failed: \(error.localizedDescription)")
//            }
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//
//    func testFetchProfileImageURL() {
//        let dummyUID = "testUser123"
//
//        let expectation = self.expectation(description: "Image URL fetch should succeed")
//
//        firestoreService.fetchProfileImageURL(uid: dummyUID) { result in
//            switch result {
//            case .success(let url):
//                XCTAssertTrue(url.contains("profile_pictures"))
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Fetching image URL failed: \(error.localizedDescription)")
//            }
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//}
