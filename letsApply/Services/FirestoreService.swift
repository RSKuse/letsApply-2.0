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
            UserProfile.CodingKeys.phone.rawValue: profile.phone,
            UserProfile.CodingKeys.location.rawValue: profile.location,
            UserProfile.CodingKeys.professionalSummary.rawValue: profile.professionalSummary,
            UserProfile.CodingKeys.jobTitle.rawValue: profile.jobTitle,
            UserProfile.CodingKeys.skills.rawValue: profile.skills,
            UserProfile.CodingKeys.qualifications.rawValue: profile.qualifications,
            UserProfile.CodingKeys.experience.rawValue: profile.experience,
            UserProfile.CodingKeys.education.rawValue: profile.education,
            UserProfile.CodingKeys.workExperiences.rawValue: profile.workExperiences.map(workExperienceData),
            UserProfile.CodingKeys.educationEntries.rawValue: profile.educationEntries.map(educationEntryData),
            UserProfile.CodingKeys.qualificationEntries.rawValue: profile.qualificationEntries.map(qualificationEntryData),
            UserProfile.CodingKeys.references.rawValue: profile.references.map(referenceData),
            UserProfile.CodingKeys.savedJobs.rawValue: profile.savedJobs,
            UserProfile.CodingKeys.isPremium.rawValue: profile.isPremium
        ]

        if let profilePictureUrl = profile.profilePictureUrl {
            data[UserProfile.CodingKeys.profilePictureUrl.rawValue] = profilePictureUrl
        }

        if let profileImageData = profile.profileImageData {
            data[UserProfile.CodingKeys.profileImageData.rawValue] = profileImageData
        }

        if let cvUrl = profile.cvUrl {
            data[UserProfile.CodingKeys.cvUrl.rawValue] = cvUrl
        }

        if let cvFileName = profile.cvFileName {
            data[UserProfile.CodingKeys.cvFileName.rawValue] = cvFileName
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
                cvUrl: nil,
                cvFileName: nil,
                professionalSummary: "",
                jobTitle: "",
                skills: ["Swift", "UIKit", "Firebase"],
                qualifications: [],
                experience: "",
                education: "",
                savedJobs: [],
                isPremium: false
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
                        cvUrl: nil,
                        cvFileName: nil,
                        professionalSummary: "",
                        jobTitle: "",
                        skills: ["Swift", "UIKit", "Firebase"],
                        qualifications: [],
                        experience: "",
                        education: "",
                        savedJobs: [],
                        isPremium: false
                    )))
                    return
                }

                completion(.success(self.mapUserProfile(from: data, fallbackUID: uid)))
            }
    }

    func fetchJobs(numberOfJobsToFetch: Int? = nil, completion: @escaping ([Job]) -> Void) {
        db.collection(FirebaseCollections.jobs.rawValue).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching jobs: \(error.localizedDescription)")
                completion(self.candidateFallbackJobs())
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(self.candidateFallbackJobs())
                return
            }

            var jobs = documents
                .map {
                    self.mapJob(from: $0.data(), documentID: $0.documentID)
                }
                .filter(\.isVisibleToCandidates)
                .sorted { $0.postingDate > $1.postingDate }

            if let numberOfJobsToFetch {
                jobs = Array(jobs.prefix(numberOfJobsToFetch))
            }

            print("Documents found: \(documents.count)")
            print("Published vacancies loaded: \(jobs.count)")

            completion(jobs.isEmpty ? self.candidateFallbackJobs() : jobs)
        }
    }

    func fetchAdminJobs(completion: @escaping (Result<[Job], Error>) -> Void) {
        db.collection(FirebaseCollections.jobs.rawValue)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let jobs = snapshot?.documents
                    .map {
                        self.mapJob(from: $0.data(), documentID: $0.documentID)
                    }
                    .sorted { $0.postingDate > $1.postingDate } ?? []
                completion(.success(jobs))
            }
    }

    func saveAdminJob(_ job: Job, completion: @escaping (Error?) -> Void) {
        let collection = db.collection(FirebaseCollections.jobs.rawValue)
        let document = job.id.map(collection.document) ?? collection.document()
        var data = mapJobData(job)
        data["updatedAt"] = FieldValue.serverTimestamp()

        if job.id == nil {
            data["createdAt"] = FieldValue.serverTimestamp()
        }

        document.setData(data, merge: false, completion: completion)
    }

    func updateJobPublicationStatus(
        jobId: String,
        status: JobPublicationStatus,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(FirebaseCollections.jobs.rawValue)
            .document(jobId)
            .setData(
                [
                    "publicationStatus": status.rawValue,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true,
                completion: completion
            )
    }

    func fetchJob(jobId: String, completion: @escaping (Result<Job, Error>) -> Void) {
        db.collection(FirebaseCollections.jobs.rawValue)
            .document(jobId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot, let data = snapshot.data() else {
                    completion(.failure(NSError(
                        domain: "JobError",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "This saved job could not be found."]
                    )))
                    return
                }

                completion(.success(self.mapJob(from: data, documentID: snapshot.documentID)))
            }
    }


    private func mapUserProfile(from data: [String: Any], fallbackUID: String) -> UserProfile {
        return UserProfile(
            uid: data[UserProfile.CodingKeys.uid.rawValue] as? String ?? fallbackUID,
            name: data[UserProfile.CodingKeys.name.rawValue] as? String ?? "Guest User",
            email: data[UserProfile.CodingKeys.email.rawValue] as? String ?? "",
            phone: data[UserProfile.CodingKeys.phone.rawValue] as? String ?? "",
            location: data[UserProfile.CodingKeys.location.rawValue] as? String ?? "South Africa",
            profilePictureUrl: data[UserProfile.CodingKeys.profilePictureUrl.rawValue] as? String ?? data["profile_picture_url"] as? String,
            profileImageData: data[UserProfile.CodingKeys.profileImageData.rawValue] as? Data,
            cvUrl: data[UserProfile.CodingKeys.cvUrl.rawValue] as? String ?? data["cv_url"] as? String,
            cvFileName: data[UserProfile.CodingKeys.cvFileName.rawValue] as? String ?? data["cv_file_name"] as? String,
            professionalSummary: data[UserProfile.CodingKeys.professionalSummary.rawValue] as? String ?? data["professional_summary"] as? String ?? "",
            jobTitle: data[UserProfile.CodingKeys.jobTitle.rawValue] as? String ?? data["job_title"] as? String ?? "",
            skills: data[UserProfile.CodingKeys.skills.rawValue] as? [String] ?? [],
            qualifications: data[UserProfile.CodingKeys.qualifications.rawValue] as? [String] ?? [],
            experience: data[UserProfile.CodingKeys.experience.rawValue] as? String ?? "",
            education: data[UserProfile.CodingKeys.education.rawValue] as? String ?? "",
            workExperiences: mapWorkExperiences(
                from: data[UserProfile.CodingKeys.workExperiences.rawValue]
            ),
            educationEntries: mapEducationEntries(
                from: data[UserProfile.CodingKeys.educationEntries.rawValue]
            ),
            qualificationEntries: mapQualificationEntries(
                from: data[UserProfile.CodingKeys.qualificationEntries.rawValue]
            ),
            references: mapReferences(
                from: data[UserProfile.CodingKeys.references.rawValue]
            ),
            savedJobs: data[UserProfile.CodingKeys.savedJobs.rawValue] as? [String] ?? data["saved_jobs"] as? [String] ?? [],
            isPremium: data[UserProfile.CodingKeys.isPremium.rawValue] as? Bool ?? false
        )
    }

    private func workExperienceData(_ entry: CVWorkExperience) -> [String: Any] {
        return [
            "id": entry.id,
            "jobTitle": entry.jobTitle,
            "company": entry.company,
            "location": entry.location,
            "startDate": entry.startDate,
            "endDate": entry.endDate,
            "responsibilities": entry.responsibilities
        ]
    }

    private func educationEntryData(_ entry: CVEducationEntry) -> [String: Any] {
        return [
            "id": entry.id,
            "qualification": entry.qualification,
            "institution": entry.institution,
            "fieldOfStudy": entry.fieldOfStudy,
            "startYear": entry.startYear,
            "endYear": entry.endYear,
            "details": entry.details
        ]
    }

    private func qualificationEntryData(_ entry: CVQualificationEntry) -> [String: Any] {
        return [
            "id": entry.id,
            "title": entry.title,
            "issuer": entry.issuer,
            "year": entry.year
        ]
    }

    private func referenceData(_ entry: CVReference) -> [String: Any] {
        return [
            "id": entry.id,
            "name": entry.name,
            "jobTitle": entry.jobTitle,
            "company": entry.company,
            "relationship": entry.relationship,
            "email": entry.email,
            "phone": entry.phone
        ]
    }

    private func mapWorkExperiences(from value: Any?) -> [CVWorkExperience] {
        guard let entries = value as? [[String: Any]] else { return [] }

        return entries.map {
            CVWorkExperience(
                id: $0["id"] as? String ?? UUID().uuidString,
                jobTitle: $0["jobTitle"] as? String ?? "",
                company: $0["company"] as? String ?? "",
                location: $0["location"] as? String ?? "",
                startDate: $0["startDate"] as? String ?? "",
                endDate: $0["endDate"] as? String ?? "",
                responsibilities: $0["responsibilities"] as? [String] ?? []
            )
        }
    }

    private func mapEducationEntries(from value: Any?) -> [CVEducationEntry] {
        guard let entries = value as? [[String: Any]] else { return [] }

        return entries.map {
            CVEducationEntry(
                id: $0["id"] as? String ?? UUID().uuidString,
                qualification: $0["qualification"] as? String ?? "",
                institution: $0["institution"] as? String ?? "",
                fieldOfStudy: $0["fieldOfStudy"] as? String ?? "",
                startYear: $0["startYear"] as? String ?? "",
                endYear: $0["endYear"] as? String ?? "",
                details: $0["details"] as? String ?? ""
            )
        }
    }

    private func mapQualificationEntries(from value: Any?) -> [CVQualificationEntry] {
        guard let entries = value as? [[String: Any]] else { return [] }

        return entries.map {
            CVQualificationEntry(
                id: $0["id"] as? String ?? UUID().uuidString,
                title: $0["title"] as? String ?? "",
                issuer: $0["issuer"] as? String ?? "",
                year: $0["year"] as? String ?? ""
            )
        }
    }

    private func mapReferences(from value: Any?) -> [CVReference] {
        guard let entries = value as? [[String: Any]] else { return [] }

        return entries.map {
            CVReference(
                id: $0["id"] as? String ?? UUID().uuidString,
                name: $0["name"] as? String ?? "",
                jobTitle: $0["jobTitle"] as? String ?? "",
                company: $0["company"] as? String ?? "",
                relationship: $0["relationship"] as? String ?? "",
                email: $0["email"] as? String ?? "",
                phone: $0["phone"] as? String ?? ""
            )
        }
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
                currency: salaryRangeData["currency"] as? String ?? data["currency"] as? String ?? "ZAR",
                period: salaryRangeData["period"] as? String
                    ?? salaryRangeData["payPeriod"] as? String
                    ?? data["salaryPeriod"] as? String
                    ?? data["payPeriod"] as? String
            ),
            benefits: compensationData["benefits"] as? [String] ?? data["benefits"] as? [String] ?? []
        )

        let application = JobApplicationInfo(
            deadline: applicationData["deadline"] as? String ?? data["applicationDeadline"] as? String ?? "Open until filled",
            applicationUrl: applicationData["applicationUrl"] as? String ?? data["applicationUrl"] as? String ?? "",
            applicationEmail: applicationData["applicationEmail"] as? String ?? data["applicationEmail"] as? String ?? "",
            contactPhone: applicationData["contactPhone"] as? String ?? data["contactPhone"] as? String ?? "",
            method: applicationData["method"] as? String ?? data["applicationMethod"] as? String ?? "",
            formName: applicationData["formName"] as? String ?? data["applicationFormName"] as? String ?? "",
            requiredForms: applicationData["requiredForms"] as? [String]
                ?? data["requiredForms"] as? [String]
                ?? [],
            requiredDocuments: applicationData["requiredDocuments"] as? [String]
                ?? data["requiredDocuments"] as? [String]
                ?? [],
            applicationInstructions: applicationData["instructions"] as? String
                ?? data["applicationInstructions"] as? String
                ?? "",
            requiresCoverLetter: applicationData["requiresCoverLetter"] as? Bool
                ?? data["requiresCoverLetter"] as? Bool
                ?? true,
            requiresCV: applicationData["requiresCV"] as? Bool
                ?? data["requiresCV"] as? Bool
                ?? true,
            requiresZ83: applicationData["requiresZ83"] as? Bool
                ?? data["requiresZ83"] as? Bool
                ?? false,
            requiresCertifiedDocuments: applicationData["requiresCertifiedDocuments"] as? Bool
                ?? data["requiresCertifiedDocuments"] as? Bool
                ?? false,
            referenceNumber: applicationData["referenceNumber"] as? String
                ?? data["referenceNumber"] as? String
                ?? "",
            postalAddress: applicationData["postalAddress"] as? String
                ?? data["postalAddress"] as? String
                ?? "",
            handDeliveryAddress: applicationData["handDeliveryAddress"] as? String
                ?? data["handDeliveryAddress"] as? String
                ?? "",
            requiresDriversLicense: applicationData["requiresDriversLicense"] as? Bool
                ?? data["requiresDriversLicense"] as? Bool
                ?? false
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
            companyLogoURL: data["companyLogoURL"] as? String
                ?? data["companyLogoUrl"] as? String
                ?? data["logoUrl"] as? String,
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
            promoted: data["promoted"] as? [String] ?? data["promotedTags"] as? [String],
            sourceName: data["sourceName"] as? String ?? "Let’s Apply",
            sourceUrl: data["sourceUrl"] as? String ?? "",
            sourceJobId: data["sourceJobId"] as? String ?? data["externalId"] as? String ?? "",
            sourceType: data["sourceType"] as? String ?? JobSourceType.manual.rawValue,
            dateImported: data["dateImported"] as? String ?? "",
            verified: data["verified"] as? Bool ?? false,
            closingDate: dateString(
                from: data["closingDate"]
                    ?? applicationData["closingDate"]
                    ?? applicationData["deadline"]
            ),
            publicationStatus: data["publicationStatus"] as? String
                ?? data["status"] as? String
                ?? JobPublicationStatus.published.rawValue
        )
    }

    private func mapJobData(_ job: Job) -> [String: Any] {
        return [
            "title": job.title,
            "companyName": job.companyName,
            "companyImageName": job.companyImageName ?? "",
            "companyLogoURL": job.companyLogoURL ?? "",
            "location": [
                "city": job.location.city,
                "region": job.location.region,
                "country": job.location.country
            ],
            "jobType": job.jobType,
            "remote": job.remote,
            "description": job.description,
            "qualifications": job.qualifications,
            "responsibilities": job.responsibilities,
            "requirements": job.requirements,
            "experience": [
                "minYears": job.experience.minYears,
                "preferredYears": job.experience.preferredYears,
                "details": job.experience.details
            ],
            "compensation": [
                "salaryRange": [
                    "min": job.compensation.salaryRange.min,
                    "max": job.compensation.salaryRange.max,
                    "currency": job.compensation.salaryRange.currency,
                    "period": job.compensation.salaryRange.period ?? SalaryPayPeriod.annum.rawValue
                ],
                "benefits": job.compensation.benefits
            ],
            "application": [
                "deadline": job.application.deadline,
                "closingDate": job.closingDate,
                "applicationUrl": job.application.applicationUrl,
                "applicationEmail": job.application.applicationEmail,
                "contactPhone": job.application.contactPhone,
                "method": job.applicationMethod.rawValue,
                "formName": job.application.formName,
                "requiredForms": job.application.requiredForms,
                "requiredDocuments": job.application.requiredDocuments,
                "instructions": job.application.applicationInstructions,
                "requiresCoverLetter": job.application.requiresCoverLetter,
                "requiresCV": job.application.requiresCV,
                "requiresZ83": job.application.requiresZ83,
                "requiresCertifiedDocuments": job.application.requiresCertifiedDocuments,
                "referenceNumber": job.application.referenceNumber,
                "postalAddress": job.application.postalAddress,
                "handDeliveryAddress": job.application.handDeliveryAddress,
                "requiresDriversLicense": job.application.requiresDriversLicense
            ],
            "jobCategory": job.jobCategory,
            "postingDate": job.postingDate,
            "closingDate": job.closingDate,
            "visibility": [
                "featured": job.visibility.featured,
                "promoted": job.visibility.promoted
            ],
            "promoted": job.promoted ?? [],
            "sourceName": job.sourceName,
            "sourceUrl": job.sourceUrl,
            "sourceJobId": job.sourceJobId,
            "sourceType": job.sourceType,
            "dateImported": job.dateImported,
            "verified": job.verified,
            "publicationStatus": job.publicationStatus
        ]
    }

    private func dateString(from value: Any?) -> String {
        if let string = value as? String {
            return string
        }

        guard let timestamp = value as? Timestamp else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp.dateValue())
    }

    private func candidateFallbackJobs() -> [Job] {
        #if DEBUG
        return Self.sampleJobs().filter(\.isVisibleToCandidates)
        #else
        return []
        #endif
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
                    salaryRange: SalaryRange(min: 18000, max: 30000, currency: "ZAR", period: "month"),
                    benefits: ["Remote", "Mentorship"]
                ),
                application: JobApplicationInfo(deadline: "Open", applicationUrl: "", applicationEmail: "careers@letsapply.co.za", contactPhone: ""),
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
                    salaryRange: SalaryRange(min: 22000, max: 35000, currency: "ZAR", period: "month"),
                    benefits: []
                ),
                application: JobApplicationInfo(deadline: "Open", applicationUrl: "", applicationEmail: "applications@example.org", contactPhone: ""),
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
                    salaryRange: SalaryRange(min: 25000, max: 38000, currency: "ZAR", period: "month"),
                    benefits: []
                ),
                application: JobApplicationInfo(deadline: "Open", applicationUrl: "", applicationEmail: "hr@example.ac.za", contactPhone: ""),
                jobCategory: "Administration",
                postingDate: "2026-06-07",
                visibility: Visibility(featured: false, promoted: false),
                promoted: nil
            )
        ]
    }

    func createApplication(
        userProfile: UserProfile,
        job: Job,
        coverLetterText: String? = nil,
        isAIGenerated: Bool = false,
        tailoredCVText: String? = nil,
        recruiterEmailSubject: String? = nil,
        recruiterEmailBody: String? = nil,
        matchScore: Int? = nil,
        status: String = "submitted",
        applicationMethod: String? = nil,
        applicationDestination: String? = nil,
        completion: @escaping (Result<Application, Error>) -> Void
    ) {
        guard !userProfile.uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(
                domain: "ApplicationError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please sign in before applying."]
            )))
            return
        }

        guard let jobId = job.id, !jobId.isEmpty else {
            completion(.failure(NSError(
                domain: "ApplicationError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "This job is missing an ID."]
            )))
            return
        }

        let applicationId = makeUserJobDocumentId(userId: userProfile.uid, jobId: jobId)
        let document = db.collection(FirebaseCollections.applications.rawValue).document(applicationId)

        let application = Application(
            id: applicationId,
            userId: userProfile.uid,
            jobId: jobId,
            jobTitle: job.title,
            companyName: job.companyName,
            appliedDate: Self.currentDateString(),
            status: status,
            cvUrl: userProfile.cvUrl,
            coverLetterText: coverLetterText,
            isAIGenerated: isAIGenerated,
            tailoredCVText: tailoredCVText,
            recruiterEmailSubject: recruiterEmailSubject,
            recruiterEmailBody: recruiterEmailBody,
            matchScore: matchScore,
            applicationMethod: applicationMethod,
            applicationDestination: applicationDestination
        )

        document.setData(mapApplicationData(application), merge: false) { error in
            if let error = error {
                completion(.failure(self.makeFirestorePermissionError(
                    fallback: "Firebase rules are blocking this application. Allow signed-in users to write their own applications, then try again.",
                    error: error
                )))
            } else {
                completion(.success(application))
            }
        }
    }

    func hasApplied(userId: String, jobId: String, completion: @escaping (Bool) -> Void) {
        let applicationId = makeUserJobDocumentId(userId: userId, jobId: jobId)
        db.collection(FirebaseCollections.applications.rawValue)
            .document(applicationId)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else {
                    completion(false)
                    return
                }

                let status = (data["status"] as? String ?? "").lowercased()
                let submittedStatuses = [
                    "submitted",
                    "sent",
                    "applied-by-email",
                    "applied-externally"
                ]
                completion(submittedStatuses.contains(status))
            }
    }

    func fetchApplications(userId: String, completion: @escaping (Result<[Application], Error>) -> Void) {
        db.collection(FirebaseCollections.applications.rawValue)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(self.makeFirestorePermissionError(
                        fallback: "Firebase rules are blocking your applications list. Allow signed-in users to read their own applications.",
                        error: error
                    )))
                    return
                }

                let applications = snapshot?.documents.map {
                    self.mapApplication(from: $0.data(), documentId: $0.documentID)
                }.sorted { $0.appliedDate > $1.appliedDate } ?? []
                completion(.success(applications))
            }
    }

    func saveJob(userId: String, job: Job, completion: @escaping (Error?) -> Void) {
        guard let jobId = job.id, !jobId.isEmpty else {
            completion(NSError(
                domain: "SavedJobError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "This job is missing an ID."]
            ))
            return
        }

        let savedJobId = makeUserJobDocumentId(userId: userId, jobId: jobId)
        let savedJob = SavedJob(
            id: savedJobId,
            userId: userId,
            jobId: jobId,
            jobTitle: job.title,
            companyName: job.companyName,
            savedDate: Self.currentDateString()
        )

        let batch = db.batch()
        let savedRef = db.collection(FirebaseCollections.savedJobs.rawValue).document(savedJobId)
        let userRef = db.collection(FirebaseCollections.users.rawValue).document(userId)

        batch.setData(mapSavedJobData(savedJob), forDocument: savedRef)
        batch.setData([
            UserProfile.CodingKeys.savedJobs.rawValue: FieldValue.arrayUnion([jobId])
        ], forDocument: userRef, merge: true)

        batch.commit(completion: completion)
    }

    func removeSavedJob(userId: String, jobId: String, completion: @escaping (Error?) -> Void) {
        let savedJobId = makeUserJobDocumentId(userId: userId, jobId: jobId)
        let batch = db.batch()
        let savedRef = db.collection(FirebaseCollections.savedJobs.rawValue).document(savedJobId)
        let userRef = db.collection(FirebaseCollections.users.rawValue).document(userId)

        batch.deleteDocument(savedRef)
        batch.setData([
            UserProfile.CodingKeys.savedJobs.rawValue: FieldValue.arrayRemove([jobId])
        ], forDocument: userRef, merge: true)

        batch.commit(completion: completion)
    }

    func isJobSaved(userId: String, jobId: String, completion: @escaping (Bool) -> Void) {
        let savedJobId = makeUserJobDocumentId(userId: userId, jobId: jobId)
        db.collection(FirebaseCollections.savedJobs.rawValue)
            .document(savedJobId)
            .getDocument { snapshot, _ in
                completion(snapshot?.exists == true)
            }
    }

    func fetchSavedJobs(userId: String, completion: @escaping (Result<[SavedJob], Error>) -> Void) {
        db.collection(FirebaseCollections.savedJobs.rawValue)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(self.makeFirestorePermissionError(
                        fallback: "Firebase rules are blocking your saved jobs list. Allow signed-in users to read their own saved jobs.",
                        error: error
                    )))
                    return
                }

                let savedJobs = snapshot?.documents.map {
                    self.mapSavedJob(from: $0.data(), documentId: $0.documentID)
                }.sorted { $0.savedDate > $1.savedDate } ?? []
                completion(.success(savedJobs))
            }
    }

    private func makeUserJobDocumentId(userId: String, jobId: String) -> String {
        return "\(userId)_\(jobId)"
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    func deleteUserData(userId: String, completion: @escaping (Error?) -> Void) {
        let collections = [
            FirebaseCollections.applications.rawValue,
            FirebaseCollections.savedJobs.rawValue
        ]
        let group = DispatchGroup()
        let lock = NSLock()
        var documentReferences: [DocumentReference] = [
            db.collection(FirebaseCollections.users.rawValue).document(userId)
        ]
        var firstError: Error?

        for collection in collections {
            group.enter()
            db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    lock.lock()
                    if firstError == nil {
                        firstError = error
                    }
                    documentReferences.append(contentsOf: snapshot?.documents.map(\.reference) ?? [])
                    lock.unlock()
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            if let firstError {
                completion(firstError)
                return
            }

            self.deleteDocuments(
                Array(documentReferences),
                completion: completion
            )
        }
    }

    private func deleteDocuments(
        _ references: [DocumentReference],
        completion: @escaping (Error?) -> Void
    ) {
        guard !references.isEmpty else {
            completion(nil)
            return
        }

        let currentBatch = Array(references.prefix(400))
        let remaining = Array(references.dropFirst(currentBatch.count))
        let batch = db.batch()
        currentBatch.forEach { reference in
            batch.deleteDocument(reference)
        }
        batch.commit { error in
            if let error {
                completion(error)
                return
            }

            self.deleteDocuments(remaining, completion: completion)
        }
    }

    private func mapApplicationData(_ application: Application) -> [String: Any] {
        var data: [String: Any] = [
            "id": application.id,
            "userId": application.userId,
            "jobId": application.jobId,
            "jobTitle": application.jobTitle,
            "companyName": application.companyName,
            "appliedDate": application.appliedDate,
            "status": application.status,
            "isAIGenerated": application.isAIGenerated ?? false
        ]

        if let cvUrl = application.cvUrl {
            data["cvUrl"] = cvUrl
        }

        if let coverLetterText = application.coverLetterText {
            data["coverLetterText"] = coverLetterText
        }

        if let tailoredCVText = application.tailoredCVText {
            data["tailoredCVText"] = tailoredCVText
        }

        if let recruiterEmailSubject = application.recruiterEmailSubject {
            data["recruiterEmailSubject"] = recruiterEmailSubject
        }

        if let recruiterEmailBody = application.recruiterEmailBody {
            data["recruiterEmailBody"] = recruiterEmailBody
        }

        if let matchScore = application.matchScore {
            data["matchScore"] = matchScore
        }

        if let applicationMethod = application.applicationMethod {
            data["applicationMethod"] = applicationMethod
        }

        if let applicationDestination = application.applicationDestination {
            data["applicationDestination"] = applicationDestination
        }

        return data
    }

    private func mapApplication(from data: [String: Any], documentId: String) -> Application {
        return Application(
            id: data["id"] as? String ?? documentId,
            userId: data["userId"] as? String ?? "",
            jobId: data["jobId"] as? String ?? "",
            jobTitle: data["jobTitle"] as? String ?? "",
            companyName: data["companyName"] as? String ?? "",
            appliedDate: data["appliedDate"] as? String ?? "",
            status: data["status"] as? String ?? "submitted",
            cvUrl: data["cvUrl"] as? String,
            coverLetterText: data["coverLetterText"] as? String,
            isAIGenerated: data["isAIGenerated"] as? Bool,
            tailoredCVText: data["tailoredCVText"] as? String,
            recruiterEmailSubject: data["recruiterEmailSubject"] as? String,
            recruiterEmailBody: data["recruiterEmailBody"] as? String,
            matchScore: data["matchScore"] as? Int,
            applicationMethod: data["applicationMethod"] as? String,
            applicationDestination: data["applicationDestination"] as? String
        )
    }

    private func mapSavedJobData(_ savedJob: SavedJob) -> [String: Any] {
        return [
            "id": savedJob.id,
            "userId": savedJob.userId,
            "jobId": savedJob.jobId,
            "jobTitle": savedJob.jobTitle,
            "companyName": savedJob.companyName,
            "savedDate": savedJob.savedDate
        ]
    }

    private func mapSavedJob(from data: [String: Any], documentId: String) -> SavedJob {
        return SavedJob(
            id: data["id"] as? String ?? documentId,
            userId: data["userId"] as? String ?? "",
            jobId: data["jobId"] as? String ?? "",
            jobTitle: data["jobTitle"] as? String ?? "",
            companyName: data["companyName"] as? String ?? "",
            savedDate: data["savedDate"] as? String ?? ""
        )
    }

    private static func currentDateString() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
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

        let storageRef = storage.reference().child("profile_pictures/\(uid)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.fetchDownloadURLWithRetry(reference: storageRef, fileType: "photo") { result in
                completion(result.map { $0.absoluteString })
            }
        }
    }

    func uploadCVDocument(
        uid: String,
        fileURL: URL,
        completion: @escaping (Result<(url: String, fileName: String), Error>) -> Void
    ) {
        let canAccessFile = fileURL.startAccessingSecurityScopedResource()
        defer {
            if canAccessFile {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let fileData = try Data(contentsOf: fileURL)
            let safeFileName = fileURL.lastPathComponent
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "_")
            let storageRef = storage.reference().child("user_cvs/\(uid)/\(safeFileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"

            storageRef.putData(fileData, metadata: metadata) { _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                self.fetchDownloadURLWithRetry(reference: storageRef, fileType: "CV") { result in
                    switch result {
                    case .success(let url):
                        completion(.success((url.absoluteString, fileURL.lastPathComponent)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func updateUserCV(
        uid: String,
        cvUrl: String,
        cvFileName: String,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(FirebaseCollections.users.rawValue)
            .document(uid)
            .setData([
                UserProfile.CodingKeys.cvUrl.rawValue: cvUrl,
                UserProfile.CodingKeys.cvFileName.rawValue: cvFileName
            ], merge: true, completion: completion)
    }

    private func fetchDownloadURLWithRetry(
        reference: StorageReference,
        fileType: String,
        attemptsRemaining: Int = 3,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        reference.downloadURL { url, error in
            if let url = url {
                completion(.success(url))
                return
            }

            guard attemptsRemaining > 0 else {
                completion(.failure(self.makeStorageUploadError(fileType: fileType, error: error)))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.fetchDownloadURLWithRetry(
                    reference: reference,
                    fileType: fileType,
                    attemptsRemaining: attemptsRemaining - 1,
                    completion: completion
                )
            }
        }
    }

    private func makeFirestorePermissionError(fallback: String, error: Error) -> Error {
        let message = error.localizedDescription
        guard message.localizedCaseInsensitiveContains("permission") else {
            return error
        }

        return NSError(
            domain: "FirestoreRules",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: fallback]
        )
    }

    private func makeStorageUploadError(fileType: String, error: Error?) -> Error {
        let rawMessage = error?.localizedDescription ?? ""
        let fileName = fileType == "CV" ? "CV" : "profile photo"

        if rawMessage.localizedCaseInsensitiveContains("object")
            || rawMessage.localizedCaseInsensitiveContains("permission")
            || rawMessage.localizedCaseInsensitiveContains("unauthorized") {
            return NSError(
                domain: "FirebaseStorageRules",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Firebase Storage is blocking or not confirming the uploaded \(fileName). Update Storage rules for profile_pictures and user_cvs, then try again."
                ]
            )
        }

        return error ?? NSError(
            domain: "FirebaseStorage",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "The \(fileName) upload could not be completed. Please try again."]
        )
    }
}
