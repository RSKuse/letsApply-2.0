# Let’s Apply Android

This is the native Android companion for Let’s Apply.

The Android app should not duplicate the business logic permanently. It should share the same backend:

- Firebase Authentication
- Cloud Firestore vacancies, applications, saved jobs, admin publishing
- DPSA and partner vacancy import pipelines
- Cloudflare Worker AI gateway
- Privacy and support pages from `/docs`

## Current Status

This first Android foundation builds a native Android shell with:

- Onboarding
- Home
- Jobs
- Search and filters
- Job Details
- Guest application gating
- Salary formatting
- Application method messaging

## Build Locally

Modern Android builds need Java 17 or newer. On this Mac, the default `java` command currently points to Java 8, so use:

```bash
cd androidApp
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=$HOME/Library/Android/sdk \
ANDROID_SDK_ROOT=$HOME/Library/Android/sdk \
./gradlew :app:assembleDebug
```

The APK will be generated at:

```text
androidApp/app/build/outputs/apk/debug/app-debug.apk
```

The next Android phase is Firebase wiring. For that you must download `google-services.json` from Firebase Console for an Android app with package name:

```text
com.simphiwe.letsapply
```

Place it at:

```text
androidApp/app/google-services.json
```

Do not commit private server secrets to Android. The OpenAI key stays only in the server environment.
