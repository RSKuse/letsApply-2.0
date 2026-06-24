//
//  FirestoreService.swift
//  letsApply
//

//
//  FirestoreService.swift
//  letsApply
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

class FirestoreService {

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            UserProfile.CodingKeys.uid.rawValue: profile.uid,
            UserProfile.CodingKeys.name.rawValue: profile.name,
            UserProfile.CodingKeys.email.rawValue: profile.email,
            UserProfile.CodingKeys.location.rawValue: profile.location,
            UserProfile.CodingKeys.jobTitle.rawValue: profile.jobTitle,
            UserProfile.CodingKeys.skills.rawValue: profile.skills,
            UserProfile.CodingKeys.qualifications.rawValue: profile.qualifications,
            UserProfile.CodingKeys.experience.rawValue: profile.experience,
            UserProfile.CodingKeys.education.rawValue: profile.education,
            UserProfile.CodingKeys.savedJobs.rawValue: profile.savedJobs
        ]

        if let profilePictureUrl = profile.profilePictureUrl {
            data[UserProfile.CodingKeys.profilePictureUrl.rawValue] = profilePictureUrl
        }

        db.collection(FirebaseCollections.users.rawValue)
            .document(profile.uid)
            .setData(data, completion: completion)
    }

    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard !uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.success(UserProfile(
                uid: "",
                name: "Guest User",
                email: "",
                location: "South Africa",
                profilePictureUrl: nil,
                jobTitle: "",
                skills: ["Swift", "UIKit", "Firebase"],
                qualifications: [],
                experience: "",
                education: "",
                savedJobs: []
            )))
            return
        }

        db.collection(FirebaseCollections.users.rawValue)
            .document(uid)
            .getDocument { snapshot, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data() else {
                    completion(.success(UserProfile(
                        uid: uid,
                        name: "Guest User",
                        email: "",
                        location: "South Africa",
                        profilePictureUrl: nil,
                        jobTitle: "",
                        skills: ["Swift", "UIKit", "Firebase"],
                        qualifications: [],
                        experience: "",
                        education: "",
                        savedJobs: []
                    )))
                    return
                }

                completion(.success(self.mapUserProfile(from: data, fallbackUID: uid)))
            }
    }

    func fetchJobs(numberOfJobsToFetch: Int? = nil, completion: @escaping ([Job]) -> Void) {
        var query: Query = db.collection(FirebaseCollections.jobs.rawValue)

        if let numberOfJobsToFetch = numberOfJobsToFetch {
            query = query.limit(to: numberOfJobsToFetch)
        }

        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                completion(Self.sampleJobs())
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(Self.sampleJobs())
                return
            }

            let jobs = documents.map { document in
                self.mapJob(from: document.data(), documentID: document.documentID)
            }
            print("Documents found: \(documents.count)")
            print("Loaded from Firestore")

            completion(jobs.isEmpty ? Self.sampleJobs() : jobs)
        }
    }


    private func mapUserProfile(from data: [String: Any], fallbackUID: String) -> UserProfile {
        return UserProfile(
            uid: data[UserProfile.CodingKeys.uid.rawValue] as? String ?? fallbackUID,
            name: data[UserProfile.CodingKeys.name.rawValue] as? String ?? "Guest User",
            email: data[UserProfile.CodingKeys.email.rawValue] as? String ?? "",
            location: data[UserProfile.CodingKeys.location.rawValue] as? String ?? "South Africa",
            profilePictureUrl: data[UserProfile.CodingKeys.profilePictureUrl.rawValue] as? String,
            jobTitle: data[UserProfile.CodingKeys.jobTitle.rawValue] as? String ?? "",
            skills: data[UserProfile.CodingKeys.skills.rawValue] as? [String] ?? [],
            qualifications: data[UserProfile.CodingKeys.qualifications.rawValue] as? [String] ?? [],
            experience: data[UserProfile.CodingKeys.experience.rawValue] as? String ?? "",
            education: data[UserProfile.CodingKeys.education.rawValue] as? String ?? "",
            savedJobs: data[UserProfile.CodingKeys.savedJobs.rawValue] as? [String] ?? []
        )
    }

    private func mapJob(from data: [String: Any], documentID: String) -> Job {
        let locationData = data["location"] as? [String: Any] ?? [:]
        let experienceData = data["experience"] as? [String: Any] ?? [:]
        let compensationData = data["compensation"] as? [String: Any] ?? [:]
        let salaryRangeData = compensationData["salaryRange"] as? [String: Any] ?? [:]
        let applicationData = data["application"] as? [String: Any] ?? [:]
        let visibilityData = data["visibility"] as? [String: Any] ?? [:]

        let companyNameValue = data["companyName"] as? String
        let companySnakeValue = data["company_name"] as? String
        let finalCompanyName = companyNameValue ?? companySnakeValue ?? "Unknown Company"

        let jobTypeValue = data["jobType"] as? String
        let jobTypeSnakeValue = data["job_type"] as? String
        let finalJobType = jobTypeValue ?? jobTypeSnakeValue ?? "Full Time"

        let location = Location(
            city: locationData["city"] as? String ?? data["city"] as? String ?? "",
            region: locationData["region"] as? String ?? data["region"] as? String ?? "",
            country: locationData["country"] as? String ?? data["country"] as? String ?? "South Africa"
        )

        let experience = Experience(
            minYears: experienceData["minYears"] as? Int ?? data["minYears"] as? Int ?? 0,
            preferredYears: experienceData["preferredYears"] as? Int ?? data["preferredYears"] as? Int ?? 0,
            details: experienceData["details"] as? String ?? data["details"] as? String ?? ""
        )

        let compensation = Compensation(
            salaryRange: SalaryRange(
                min: salaryRangeData["min"] as? Int ?? data["minSalary"] as? Int ?? 0,
                max: salaryRangeData["max"] as? Int ?? data["maxSalary"] as? Int ?? 0,
                currency: salaryRangeData["currency"] as? String ?? data["currency"] as? String ?? "ZAR"
            ),
            benefits: compensationData["benefits"] as? [String] ?? data["benefits"] as? [String] ?? []
        )

        let application = Application(
            deadline: applicationData["deadline"] as? String ?? data["applicationDeadline"] as? String ?? "Open until filled",
            applicationUrl: applicationData["applicationUrl"] as? String ?? data["applicationUrl"] as? String ?? "",
            applicationEmail: applicationData["applicationEmail"] as? String ?? data["applicationEmail"] as? String ?? "",
            contactPhone: applicationData["contactPhone"] as? String ?? data["contactPhone"] as? String ?? ""
        )

        let visibility = Visibility(
            featured: visibilityData["featured"] as? Bool ?? data["featured"] as? Bool ?? false,
            promoted: visibilityData["promoted"] as? Bool ?? data["isPromoted"] as? Bool ?? false
        )

        return Job(
            id: documentID,
            title: data["title"] as? String ?? "Untitled Vacancy",
            companyName: finalCompanyName,
            companyImageName: data["companyImageName"] as? String ?? data["company_image_name"] as? String,
            location: location,
            jobType: finalJobType,
            remote: data["remote"] as? Bool ?? false,
            description: data["description"] as? String ?? "No description available.",
            qualifications: data["qualifications"] as? [String] ?? [],
            responsibilities: data["responsibilities"] as? [String] ?? [],
            requirements: data["requirements"] as? [String] ?? [],
            experience: experience,
            compensation: compensation,
            application: application,
            jobCategory: data["jobCategory"] as? String ?? "General",
            postingDate: data["postingDate"] as? String ?? "",
            visibility: visibility,
            promoted: data["promoted"] as? [String] ?? data["promotedTags"] as? [String]
        )
    }

    static func sampleJobs() -> [Job] {
        return [
            Job(
                id: "sample-1",
                title: "Junior iOS Developer",
                companyName: "Lets Apply Labs",
                companyImageName: "job_placeholder",
                location: Location(city: "Durban", region: "KwaZulu-Natal", country: "South Africa"),
                jobType: "Full Time",
                remote: true,
                description: "Build clean UIKit screens, connect job data, and support a modern employment platform for young professionals.",
                qualifications: ["Swift", "UIKit", "Firebase"],
                responsibilities: ["Build screens", "Fix bugs", "Improve UI"],
                requirements: ["Swift", "UIKit", "MVVM"],
                experience: Experience(minYears: 0, preferredYears: 1, details: "Portfolio projects accepted"),
                compensation: Compensation(
                    salaryRange: SalaryRange(min: 18000, max: 30000, currency: "ZAR"),
                    benefits: ["Remote", "Mentorship"]
                ),
                application: Application(deadline: "Open", applicationUrl: "", applicationEmail: "careers@letsapply.co.za", contactPhone: ""),
                jobCategory: "Technology",
                postingDate: "2026-06-07",
                visibility: Visibility(featured: true, promoted: true),
                promoted: ["Recommended"]
            ),
            Job(
                id: "sample-2",
                title: "Research Assistant",
                companyName: "Public Policy Centre",
                companyImageName: "job_placeholder",
                location: Location(city: "Pretoria", region: "Gauteng", country: "South Africa"),
                jobType: "Contract",
                remote: false,
                description: "Support research, data collection, literature reviews, and monitoring reports for public sector projects.",
                qualifications: ["Research", "Monitoring and Evaluation", "Report Writing"],
                responsibilities: ["Collect data", "Prepare summaries", "Support evaluations"],
                requirements: ["Research", "Excel", "Writing"],
                experience: Experience(minYears: 1, preferredYears: 2, details: "Public sector experience preferred"),
                compensation: Compensation(
                    salaryRange: SalaryRange(min: 22000, max: 35000, currency: "ZAR"),
                    benefits: []
                ),
                application: Application(deadline: "Open", applicationUrl: "", applicationEmail: "applications@example.org", contactPhone: ""),
                jobCategory: "Research",
                postingDate: "2026-06-07",
                visibility: Visibility(featured: true, promoted: false),
                promoted: nil
            ),
            Job(
                id: "sample-3",
                title: "Administration Officer",
                companyName: "Regent Business School",
                companyImageName: "job_placeholder",
                location: Location(city: "Durban", region: "KwaZulu-Natal", country: "South Africa"),
                jobType: "Permanent",
                remote: false,
                description: "Coordinate assessments, support students, maintain accurate records, and assist with academic administration.",
                qualifications: ["Administration", "Microsoft 365", "Communication"],
                responsibilities: ["Coordinate documents", "Support stakeholders", "Maintain records"],
                requirements: ["Administration", "Excel", "Communication"],
                experience: Experience(minYears: 2, preferredYears: 3, details: "Higher education experience advantageous"),
                compensation: Compensation(
                    salaryRange: SalaryRange(min: 25000, max: 38000, currency: "ZAR"),
                    benefits: []
                ),
                application: Application(deadline: "Open", applicationUrl: "", applicationEmail: "hr@example.ac.za", contactPhone: ""),
                jobCategory: "Administration",
                postingDate: "2026-06-07",
                visibility: Visibility(featured: false, promoted: false),
                promoted: nil
            )
        ]
    }

    func uploadProfileImage(uid: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(
                domain: "ImageConversionError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."]
            )))
            return
        }

        let storageRef = storage.reference().child("profile_pictures/\(uid).jpg")

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
}
