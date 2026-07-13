# Let’s Apply Android Companion Roadmap

Android is a product requirement for Let’s Apply because many job seekers will discover and use the platform on Android first.

The iOS app remains the flagship UIKit build, but Android should share the same backend instead of becoming a separate product.

## Shared Backend

Both iOS and Android should use:

- Firebase Authentication
- Cloud Firestore vacancies
- Cloud Firestore applications and saved jobs
- DPSA and partner vacancy import pipelines
- Cloudflare Worker AI gateway
- GitHub Pages privacy and support URLs

## Android Phases

### Phase A: Native Android Foundation

Status: started.

- Native Android app under `androidApp`
- Programmatic UI
- Onboarding
- Home
- Jobs
- Search and filters
- Job Details
- Guest application gating
- Salary formatting

### Phase B: Firebase Android Setup

Required from Firebase Console:

- Add Android app package `com.simphiwe.letsapply`
- Download `google-services.json`
- Place it at `androidApp/app/google-services.json`
- Enable Email/Password and Anonymous Auth providers

Then wire:

- Anonymous guest mode
- Register and sign in
- Firestore jobs
- User profiles
- Saved jobs
- Applications

Status: Android is now Firebase-ready. It will keep using local preview jobs until `google-services.json` is added, then it can authenticate anonymously and load published jobs from Firestore.

### Phase C: Application Flows

Bring Android to parity with iOS:

- Internal Let’s Apply applications: route placeholder added
- Email applications: email composer route added
- Employer website applications: browser route added
- Government applications
- Z83 checklist and document export
- Application tracking

### Phase D: Secure AI

Use the same server-backed AI gateway as iOS.

The OpenAI key must never be inside the Android app. Android should call the Cloudflare Worker with a Firebase ID token.

### Phase E: Play Store Release

Prepare:

- App signing
- Play Console listing
- Privacy policy URL
- Data safety form
- Screenshots
- Internal testing
- Closed testing if required
- Production release

## Important Principle

Do not maintain two different Let’s Apply products.

iOS and Android can have native interfaces, but job data, applications, AI, privacy, and business rules must come from the same backend.
