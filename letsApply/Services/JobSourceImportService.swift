//
//  JobSourceImportService.swift
//  letsApply
//

import Foundation

final class JobSourceImportService {

    enum Provider {
        case greenhouse(token: String)
        case lever(site: String, isEuropean: Bool)
        case dpsa
        case restrictedPartner(name: String)
        case unsupported
    }

    enum ImportError: LocalizedError {
        case invalidURL
        case partnerAccessRequired(String)
        case dpsaManaged
        case unsupportedSource
        case invalidResponse
        case noVacancies

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Enter a complete HTTPS careers or vacancy URL."
            case .partnerAccessRequired(let provider):
                return "Partner access required. \(provider) does not permit unrestricted vacancy importing. Add an approved API or feed agreement before using this source."
            case .dpsaManaged:
                return "DPSA circulars are already handled by the secure Friday and Saturday importer. Run “Import DPSA vacancies” in GitHub Actions when you need an immediate refresh."
            case .unsupportedSource:
                return "No approved public job feed was detected. Publish the vacancy manually or obtain an official API, RSS feed, or partner agreement from this source."
            case .invalidResponse:
                return "The provider returned information Let’s Apply could not read."
            case .noVacancies:
                return "This source currently has no published vacancies."
            }
        }
    }

    func detectProvider(from rawValue: String) throws -> Provider {
        guard let url = normalizedURL(from: rawValue),
              let host = url.host?.lowercased() else {
            throw ImportError.invalidURL
        }

        let components = url.pathComponents.filter { $0 != "/" }
        if host.contains("greenhouse.io") {
            guard let token = components.first, !token.isEmpty else {
                throw ImportError.invalidURL
            }
            return .greenhouse(token: token)
        }

        if host.contains("lever.co") {
            guard let site = components.first, !site.isEmpty else {
                throw ImportError.invalidURL
            }
            return .lever(site: site, isEuropean: host.contains("eu.lever.co"))
        }

        if host.contains("dpsa.gov.za") {
            return .dpsa
        }

        let restrictedProviders: [(hostFragment: String, name: String)] = [
            ("linkedin.com", "LinkedIn"),
            ("indeed.", "Indeed"),
            ("pnet.co.za", "PNet"),
            ("careers24.com", "Careers24"),
            ("careerjunction.co.za", "CareerJunction"),
            ("glassdoor.", "Glassdoor"),
            ("ziprecruiter.", "ZipRecruiter"),
            ("upwork.com", "Upwork")
        ]
        if let match = restrictedProviders.first(where: {
            host.contains($0.hostFragment)
        }) {
            return .restrictedPartner(name: match.name)
        }

        return .unsupported
    }

    func importVacancies(
        from rawValue: String,
        completion: @escaping (Result<[Job], Error>) -> Void
    ) {
        do {
            switch try detectProvider(from: rawValue) {
            case .greenhouse(let token):
                fetchGreenhouseJobs(token: token, completion: completion)
            case .lever(let site, let isEuropean):
                fetchLeverJobs(site: site, isEuropean: isEuropean, completion: completion)
            case .dpsa:
                completion(.failure(ImportError.dpsaManaged))
            case .restrictedPartner(let name):
                completion(.failure(ImportError.partnerAccessRequired(name)))
            case .unsupported:
                completion(.failure(ImportError.unsupportedSource))
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func fetchGreenhouseJobs(
        token: String,
        completion: @escaping (Result<[Job], Error>) -> Void
    ) {
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? token
        guard let url = URL(
            string: "https://boards-api.greenhouse.io/v1/boards/\(encodedToken)/jobs?content=true"
        ) else {
            completion(.failure(ImportError.invalidURL))
            return
        }

        fetch(url: url, as: GreenhouseResponse.self) { result in
            switch result {
            case .success(let response):
                let company = self.displayName(from: token)
                let jobs = response.jobs.map {
                    self.makeGreenhouseJob($0, company: company, token: token)
                }
                completion(jobs.isEmpty ? .failure(ImportError.noVacancies) : .success(jobs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchLeverJobs(
        site: String,
        isEuropean: Bool,
        completion: @escaping (Result<[Job], Error>) -> Void
    ) {
        let host = isEuropean ? "api.eu.lever.co" : "api.lever.co"
        let encodedSite = site.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? site
        guard let url = URL(
            string: "https://\(host)/v0/postings/\(encodedSite)?mode=json"
        ) else {
            completion(.failure(ImportError.invalidURL))
            return
        }

        fetch(url: url, as: [LeverPosting].self) { result in
            switch result {
            case .success(let response):
                let company = self.displayName(from: site)
                let jobs = response.map {
                    self.makeLeverJob($0, company: company, site: site)
                }
                completion(jobs.isEmpty ? .failure(ImportError.noVacancies) : .success(jobs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetch<Value: Decodable>(
        url: URL,
        as type: Value.Type,
        completion: @escaping (Result<Value, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("LetsApplyAdminImporter/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let data else {
                completion(.failure(ImportError.invalidResponse))
                return
            }

            do {
                completion(.success(try JSONDecoder().decode(Value.self, from: data)))
            } catch {
                completion(.failure(ImportError.invalidResponse))
            }
        }.resume()
    }

    private func makeGreenhouseJob(
        _ value: GreenhouseJob,
        company: String,
        token: String
    ) -> Job {
        let location = value.location?.name ?? ""
        return makeJob(
            id: "greenhouse_\(token)_\(value.id)",
            title: value.title,
            company: company,
            location: location,
            description: plainText(from: value.content),
            jobType: "Not specified",
            remote: location.lowercased().contains("remote"),
            category: value.departments?.first?.name ?? "General",
            postingDate: dateOnly(from: value.updatedAt),
            sourceName: "\(company) - Greenhouse",
            sourceURL: value.absoluteURL,
            sourceJobId: String(value.id)
        )
    }

    private func makeLeverJob(
        _ value: LeverPosting,
        company: String,
        site: String
    ) -> Job {
        let location = value.categories?.location ?? ""
        let requirements = value.lists?
            .filter {
                let title = $0.text.lowercased()
                return title.contains("require") || title.contains("qualif")
            }
            .map { plainText(from: $0.content) } ?? []
        let responsibilities = value.lists?
            .filter {
                let title = $0.text.lowercased()
                return !title.contains("require") && !title.contains("qualif")
            }
            .map { plainText(from: $0.content) } ?? []

        return makeJob(
            id: "lever_\(site)_\(value.id)",
            title: value.text,
            company: company,
            location: location,
            description: plainText(
                from: value.descriptionPlain ?? value.description ?? value.additionalPlain ?? ""
            ),
            requirements: requirements,
            responsibilities: responsibilities,
            jobType: value.categories?.commitment ?? "Not specified",
            remote: value.workplaceType?.lowercased() == "remote"
                || location.lowercased().contains("remote"),
            category: value.categories?.team ?? "General",
            postingDate: "",
            sourceName: "\(company) - Lever",
            sourceURL: value.hostedURL ?? value.applyURL ?? "",
            sourceJobId: value.id
        )
    }

    private func makeJob(
        id: String,
        title: String,
        company: String,
        location: String,
        description: String,
        requirements: [String] = [],
        responsibilities: [String] = [],
        jobType: String,
        remote: Bool,
        category: String,
        postingDate: String,
        sourceName: String,
        sourceURL: String,
        sourceJobId: String
    ) -> Job {
        Job(
            id: sanitizedDocumentId(id),
            title: title,
            companyName: company,
            companyImageName: nil,
            location: Location(city: location, region: "", country: ""),
            jobType: jobType,
            remote: remote,
            description: description,
            qualifications: [],
            responsibilities: responsibilities,
            requirements: requirements,
            experience: Experience(minYears: 0, preferredYears: 0, details: ""),
            compensation: Compensation(
                salaryRange: SalaryRange(min: 0, max: 0, currency: "", period: "annum"),
                benefits: []
            ),
            application: JobApplicationInfo(
                deadline: "Open until filled",
                applicationUrl: sourceURL,
                applicationEmail: "",
                contactPhone: "",
                method: JobApplicationMethod.externalWebsite.rawValue,
                applicationInstructions: "Review and submit on the employer’s official application page.",
                requiresCoverLetter: false,
                requiresCV: true
            ),
            jobCategory: category,
            postingDate: postingDate.isEmpty ? currentDate() : postingDate,
            visibility: Visibility(featured: false, promoted: false),
            promoted: nil,
            sourceName: sourceName,
            sourceUrl: sourceURL,
            sourceJobId: sourceJobId,
            sourceType: JobSourceType.companyWebsite.rawValue,
            dateImported: ISO8601DateFormatter().string(from: Date()),
            verified: true,
            publicationStatus: JobPublicationStatus.published.rawValue
        )
    }

    private func normalizedURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.scheme == "https" else {
            return nil
        }
        return url
    }

    private func displayName(from token: String) -> String {
        token
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func plainText(from html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func dateOnly(from value: String?) -> String {
        guard let value, value.count >= 10 else { return currentDate() }
        return String(value.prefix(10))
    }

    private func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func sanitizedDocumentId(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .prefix(180)
            .lowercased()
    }
}

private struct GreenhouseResponse: Decodable {
    let jobs: [GreenhouseJob]
}

private struct GreenhouseJob: Decodable {
    let id: Int
    let title: String
    let absoluteURL: String
    let content: String
    let updatedAt: String?
    let location: GreenhouseLocation?
    let departments: [GreenhouseDepartment]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case absoluteURL = "absolute_url"
        case content
        case updatedAt = "updated_at"
        case location
        case departments
    }
}

private struct GreenhouseLocation: Decodable {
    let name: String
}

private struct GreenhouseDepartment: Decodable {
    let name: String
}

private struct LeverPosting: Decodable {
    let id: String
    let text: String
    let hostedURL: String?
    let applyURL: String?
    let description: String?
    let descriptionPlain: String?
    let additionalPlain: String?
    let workplaceType: String?
    let categories: LeverCategories?
    let lists: [LeverList]?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case hostedURL = "hostedUrl"
        case applyURL = "applyUrl"
        case description
        case descriptionPlain
        case additionalPlain
        case workplaceType
        case categories
        case lists
    }
}

private struct LeverCategories: Decodable {
    let team: String?
    let location: String?
    let commitment: String?
}

private struct LeverList: Decodable {
    let text: String
    let content: String
}
