# Firebase Android Setup

Android needs its own Firebase app registration. The iOS `GoogleService-Info.plist` cannot be reused directly by Android.

## Step By Step

1. Open Firebase Console.
2. Select the `letsApply` project.
3. Go to Project settings.
4. Under **Your apps**, click the Android icon.
5. Use this Android package name:

```text
com.simphiwe.letsapply
```

6. App nickname can be:

```text
Let’s Apply Android
```

7. Download `google-services.json`.
8. Put it here:

```text
androidApp/app/google-services.json
```

9. Do not put OpenAI, Gemini, service account, or server secrets in Android.
10. Build Android:

```bash
cd androidApp
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=$HOME/Library/Android/sdk \
ANDROID_SDK_ROOT=$HOME/Library/Android/sdk \
./gradlew :app:assembleDebug
```

## Why This Is Required

The Android app must identify itself to Firebase before it can:

- Sign users in anonymously
- Register users with email/password
- Read published jobs
- Save profiles
- Save applications
- Sync saved jobs

The app already keeps the OpenAI key out of Android. Android will call the secure AI server later using the user’s Firebase ID token.
