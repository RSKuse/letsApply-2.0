# Let's Apply Release Readiness

## Implemented

- UIKit, programmatic navigation, splash, onboarding, guest browsing, registration, sign-in, profile, CV Studio, local PDF generation, saved jobs, job details, adaptive application review, and application tracking.
- Internal, email, employer-website, government email, government website, circular, and manual application routes.
- User-approved email and external application flows.
- Protected vacancy publishing for admin users.
- Published and unexpired vacancy filtering.
- Free compressed profile avatars stored in each user's private Firestore profile.
- In-app privacy information and permanent account deletion.
- App icon, privacy manifest, iOS 15 deployment target, and reproducible CocoaPods install.
- DPSA circular importer with Friday automation and a Saturday retry.
- Daily Greenhouse and Lever partner-feed importer with safe job expiry.
- Trusted remote company logos with a branded fallback.
- Profile-based ranking for the home-screen recommendations.

## External Setup Required

1. Publish `firebase/firestore.rules` in Firebase Console.
2. In Firebase Authentication, enable Email/Password and Anonymous providers.
3. Create `admins/{your Firebase uid}` with Boolean field `active: true`.
4. Add a protected GitHub Actions secret named `FIREBASE_SERVICE_ACCOUNT`, then run **Import DPSA vacancies**.
5. Add approved `GREENHOUSE_BOARDS_JSON` and `LEVER_SITES_JSON` repository variables, then run **Import partner vacancies**.
6. Enable GitHub Pages from the `/docs` folder on `main`.
7. Enrol in the Apple Developer Program or obtain an eligible organization fee waiver.
8. Create the App Store Connect record for bundle ID `com.simphiwe.letsApply`.
9. Enter the GitHub Pages privacy and support URLs in App Store Connect.
10. Complete App Privacy, age rating, content rights, export compliance, pricing, territories, review notes, and screenshots.
11. Test email composition and document sharing on a physical iPhone before submission.

## Production Hardening

- Enable Firebase App Check before broad public release.
- Restrict the Firebase iOS API key to the bundle ID and required Firebase APIs.
- Never add a Gemini, OpenAI, service-account, or other server API secret to the iOS app.
- Only ingest vacancies from official public feeds, approved partners, or sources whose terms permit reuse.
