//
//  letsApplyTests.swift
//  letsApplyTests
//
//  Created by Reuben Simphiwe Kuse on 2024/12/01.
//

import Testing
@testable import letsApply

struct letsApplyTests {

    @Test func detectsApprovedGreenhouseSource() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://boards.greenhouse.io/openai"
        )

        guard case .greenhouse(let token) = provider else {
            Issue.record("Expected a Greenhouse source")
            return
        }
        #expect(token == "openai")
    }

    @Test func detectsApprovedLeverSource() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://jobs.lever.co/example"
        )

        guard case .lever(let site, let isEuropean) = provider else {
            Issue.record("Expected a Lever source")
            return
        }
        #expect(site == "example")
        #expect(isEuropean == false)
    }

    @Test func marksLinkedInAsRestrictedPartner() throws {
        let provider = try JobSourceImportService().detectProvider(
            from: "https://www.linkedin.com/jobs/view/123"
        )

        guard case .restrictedPartner(let name) = provider else {
            Issue.record("Expected a restricted partner source")
            return
        }
        #expect(name == "LinkedIn")
    }

    @Test func z83RequiresLegalReviewAndSignature() {
        let profile = Z83ApplicationProfile(fullName: "Example Candidate")

        #expect(profile.isComplete == false)
        #expect(profile.missingRequiredFields.contains("Signature"))
        #expect(profile.missingRequiredFields.contains("Declaration acceptance"))
    }

}
