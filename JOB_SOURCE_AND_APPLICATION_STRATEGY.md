# Let's Apply Job Source and Application Strategy

## Product Rule

Let's Apply prepares the strongest application package it can, but the user always reviews and approves the final submission. The app must never claim that an external application was submitted when it only opened an email, website, or form.

## Trusted Job Sources

1. **Manual and curated jobs**
   - Let’s Apply administrators add verified vacancies to Firestore.
   - Best starting point while the recruiter portal and ingestion backend are being built.

2. **Recruiter submissions**
   - Approved recruiters post directly through a future recruiter portal.
   - Every recruiter and vacancy should pass a verification workflow before publication.

3. **South African government vacancies**
   - Import or curate vacancies from the official [DPSA Public Service Vacancy Circular](https://www.dpsa.gov.za/newsroom/psvc/).
   - The circular is normally published weekly and provides the official Z83 form and department-specific application instructions.
   - Preserve the vacancy reference number, closing date, destination, required forms, and supporting-document instructions.
   - The `Import DPSA vacancies` GitHub Action checks on Friday evening and retries on Saturday morning. Stable vacancy IDs prevent duplicates, while closing dates automatically hide expired posts.

4. **Employer applicant-tracking systems**
   - Use approved public or partner feeds such as the [Greenhouse Job Board API](https://developer.greenhouse.io/job-board.html) and [Lever Postings API](https://github.com/lever/postings-api).
   - Prefer each provider’s hosted application form unless Let’s Apply has permission and secure server-side credentials for direct submission.
   - The `Import partner vacancies` GitHub Action checks configured Greenhouse and Lever feeds daily.
   - ReliefWeb can be enabled after Let’s Apply receives an approved API app name.

5. **Licensed job-data partners**
   - Evaluate commercial providers such as the [Adzuna API](https://developer.adzuna.com/) when the product can support licensing and usage costs.

Do not scrape websites that prohibit automated access. Job ingestion belongs in a secure backend service, not directly inside the iOS app.

## Normalized Firestore Job Fields

Each job should include:

- `sourceName`
- `sourceUrl`
- `sourceJobId`
- `sourceType`
- `dateImported`
- `verified`
- `companyLogoURL`
- `application.method`
- `application.applicationEmail`
- `application.applicationUrl`
- `application.formName`
- `application.requiredForms`
- `application.requiredDocuments`
- `application.instructions`
- `application.requiresCV`
- `application.requiresCoverLetter`
- `application.requiresZ83`
- `application.requiresCertifiedDocuments`
- `compensation.salaryRange.currency`
- `compensation.salaryRange.min`
- `compensation.salaryRange.max`
- `compensation.salaryRange.period`

Use `sourceType + sourceJobId` to prevent duplicate imported vacancies.
Only use an HTTPS logo URL supplied by the employer or an approved source. The
app keeps its branded briefcase fallback when a trustworthy logo is unavailable.

## Application Routing

| Vacancy method | Let’s Apply action | Final user action |
| --- | --- | --- |
| Internal | Submit the approved package and track it | Confirm submission |
| Email | Prepare recipient, subject, body, CV PDF, and cover-letter PDF | Review and tap Send in Mail |
| External portal | Export the package and open the official URL | Complete portal questions and submit |
| Government or required form | Show checklist, export documents, and open the official form | Complete declarations, sign, and submit |
| Manual instructions | Show the employer’s instructions and export the package | Follow the stated delivery method |

## Delivery Phases

1. Curated Firestore jobs and application routing.
2. Recruiter portal with verification.
3. Backend import service for official and approved feeds.
4. Job expiry, deduplication, and source-health monitoring.
5. Direct partner submissions only where an agreement and supported API allow them.
