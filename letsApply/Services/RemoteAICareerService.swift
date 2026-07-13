//
//  RemoteAICareerService.swift
//  letsApply
//

import Foundation
import FirebaseAuth

final class RemoteAICareerService {

    enum Task: String {
        case coverLetter
        case tailorCV
        case improveCV
        case applicationEmail
        case autoApplyPackage
    }

    enum ServiceError: LocalizedError {
        case notConfigured
        case authenticationRequired
        case invalidResponse
        case serviceMessage(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Secure AI generation is not available yet."
            case .authenticationRequired:
                return "Sign in before using AI career tools."
            case .invalidResponse:
                return "The AI service returned an invalid response."
            case .serviceMessage(let message):
                return message
            }
        }
    }

    var isConfigured: Bool {
        serviceURL != nil
    }

    func generateText(
        task: Task,
        userProfile: UserProfile,
        job: Job,
        currentDraft: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        send(
            task: task,
            userProfile: userProfile,
            job: job,
            currentDraft: currentDraft
        ) { result in
            switch result {
            case .success(let response):
                guard let text = response.text, !text.isEmpty else {
                    completion(.failure(ServiceError.invalidResponse))
                    return
                }
                completion(.success(text))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func generatePackage(
        userProfile: UserProfile,
        job: Job,
        completion: @escaping (Result<AutoApplyPackage, Error>) -> Void
    ) {
        send(
            task: .autoApplyPackage,
            userProfile: userProfile,
            job: job,
            currentDraft: nil
        ) { result in
            switch result {
            case .success(let response):
                guard let package = response.package else {
                    completion(.failure(ServiceError.invalidResponse))
                    return
                }
                completion(.success(AutoApplyPackage(
                    matchScore: min(max(package.matchScore, 0), 100),
                    matchSummary: package.matchSummary,
                    missingSkills: package.missingSkills,
                    recommendations: package.recommendations,
                    tailoredCVText: package.tailoredCVText,
                    coverLetterText: package.coverLetterText,
                    emailSubject: package.emailSubject,
                    emailBody: package.emailBody,
                    isAIGenerated: true
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func send(
        task: Task,
        userProfile: UserProfile,
        job: Job,
        currentDraft: String?,
        completion: @escaping (Result<CareerResponse, Error>) -> Void
    ) {
        guard let serviceURL = serviceURL else {
            completion(.failure(ServiceError.notConfigured))
            return
        }

        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            completion(.failure(ServiceError.authenticationRequired))
            return
        }

        user.getIDToken { [weak self] token, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let token = token, !token.isEmpty else {
                completion(.failure(ServiceError.authenticationRequired))
                return
            }

            do {
                let requestBody = CareerRequest(
                    task: task.rawValue,
                    profile: ProfilePayload(profile: userProfile),
                    job: JobPayload(job: job),
                    currentDraft: currentDraft
                )
                var request = URLRequest(url: serviceURL)
                request.httpMethod = "POST"
                request.timeoutInterval = 90
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONEncoder().encode(requestBody)

                self.session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse,
                          let data = data else {
                        completion(.failure(ServiceError.invalidResponse))
                        return
                    }

                    let decoded = try? JSONDecoder().decode(CareerResponse.self, from: data)
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        let message = decoded?.error
                            ?? "The AI service is temporarily unavailable."
                        completion(.failure(ServiceError.serviceMessage(message)))
                        return
                    }

                    guard let decoded = decoded else {
                        completion(.failure(ServiceError.invalidResponse))
                        return
                    }
                    completion(.success(decoded))
                }
                .resume()
            } catch {
                completion(.failure(error))
            }
        }
    }

    private var serviceURL: URL? {
        #if DEBUG
        if let debugValue = ProcessInfo.processInfo.environment[
            "LETSAPPLY_AI_SERVICE_URL"
        ],
           let url = endpointURL(from: debugValue) {
            return url
        }
        #endif

        guard let configuredValue = Bundle.main.object(
            forInfoDictionaryKey: "AIServiceBaseURL"
        ) as? String else {
            return nil
        }
        return endpointURL(from: configuredValue)
    }

    private func endpointURL(from value: String) -> URL? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              !cleaned.contains("$("),
              let baseURL = URL(string: cleaned),
              let scheme = baseURL.scheme?.lowercased(),
              scheme == "https" || isLocalDebugURL(baseURL) else {
            return nil
        }

        return baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("career")
    }

    private func isLocalDebugURL(_ url: URL) -> Bool {
        #if DEBUG
        return url.scheme?.lowercased() == "http"
            && ["127.0.0.1", "localhost"].contains(url.host?.lowercased() ?? "")
        #else
        return false
        #endif
    }

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()
}

private struct CareerRequest: Encodable {
    let task: String
    let profile: ProfilePayload
    let job: JobPayload
    let currentDraft: String?
}

private struct ProfilePayload: Encodable {
    let name: String
    let location: String
    let desiredJobTitle: String
    let professionalSummary: String
    let skills: [String]
    let workExperience: [String]
    let education: [String]
    let certificates: [String]

    init(profile: UserProfile) {
        name = profile.name
        location = profile.location
        desiredJobTitle = profile.jobTitle
        professionalSummary = profile.professionalSummary
        skills = profile.skills
        workExperience = profile.resolvedWorkExperiences.map { experience in
            [
                [experience.jobTitle, experience.company]
                    .filter { !$0.isEmpty }
                    .joined(separator: " at "),
                experience.dateRange,
                experience.responsibilities.joined(separator: " ")
            ]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        }
        education = profile.resolvedEducationEntries.map { entry in
            [
                entry.qualification,
                entry.fieldOfStudy,
                entry.institution,
                entry.dateRange,
                entry.details
            ]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        }
        certificates = profile.resolvedQualificationEntries.map { entry in
            [entry.title, entry.issuer, entry.year]
                .filter { !$0.isEmpty }
                .joined(separator: " | ")
        }
    }
}

private struct JobPayload: Encodable {
    let title: String
    let company: String
    let location: String
    let description: String
    let requirements: [String]
    let responsibilities: [String]
    let qualifications: [String]
    let referenceNumber: String
    let applicationMethod: String

    init(job: Job) {
        title = job.title
        company = job.companyName
        location = job.locationText
        description = job.description
        requirements = job.requirements
        responsibilities = job.responsibilities
        qualifications = job.qualifications
        referenceNumber = job.application.referenceNumber
        applicationMethod = job.applicationMethod.rawValue
    }
}

private struct CareerResponse: Decodable {
    let text: String?
    let package: RemotePackage?
    let error: String?
}

private struct RemotePackage: Decodable {
    let matchScore: Int
    let matchSummary: String
    let missingSkills: [String]
    let recommendations: [String]
    let tailoredCVText: String
    let coverLetterText: String
    let emailSubject: String
    let emailBody: String
}
