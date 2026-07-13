package com.simphiwe.letsapply;

import android.content.Context;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;

import java.util.HashMap;
import java.util.Map;

final class FirestoreUserRepository {
    interface Completion {
        void onComplete(boolean success, String message);
    }

    interface ProfileCallback {
        void onProfileLoaded(Map<String, Object> profile);
        void onProfileUnavailable(String message);
    }

    private final Context context;

    FirestoreUserRepository(Context context) {
        this.context = context.getApplicationContext();
    }

    boolean isConfigured() {
        return !FirebaseApp.getApps(context).isEmpty();
    }

    void fetchProfile(ProfileCallback callback) {
        withUser((user, error) -> {
            if (user == null) {
                callback.onProfileUnavailable(error);
                return;
            }

            FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(user.getUid())
                    .get()
                    .addOnSuccessListener(document -> {
                        if (document.exists() && document.getData() != null) {
                            callback.onProfileLoaded(document.getData());
                        } else {
                            callback.onProfileUnavailable("No profile saved yet.");
                        }
                    })
                    .addOnFailureListener(failure -> callback.onProfileUnavailable(failure.getLocalizedMessage()));
        });
    }

    void saveProfile(Map<String, Object> profile, Completion completion) {
        withUser((user, error) -> {
            if (user == null) {
                completion.onComplete(false, error);
                return;
            }

            Map<String, Object> payload = new HashMap<>(profile);
            payload.put("uid", user.getUid());
            payload.put("isAnonymous", user.isAnonymous());
            payload.put("updatedAt", System.currentTimeMillis());

            FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(user.getUid())
                    .set(payload, SetOptions.merge())
                    .addOnSuccessListener(unused -> completion.onComplete(true, "Profile saved to Firebase."))
                    .addOnFailureListener(failure -> completion.onComplete(false, failure.getLocalizedMessage()));
        });
    }

    void saveApplication(Job job, String status, String cvText, String coverLetter, String emailDraft, int matchScore, Completion completion) {
        withUser((user, error) -> {
            if (user == null) {
                completion.onComplete(false, error);
                return;
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("userId", user.getUid());
            payload.put("jobId", documentSafeId(jobKey(job)));
            payload.put("jobKey", jobKey(job));
            payload.put("jobTitle", job.title);
            payload.put("companyName", job.company);
            payload.put("applicationMethod", job.method);
            payload.put("status", status);
            payload.put("submittedDate", System.currentTimeMillis());
            payload.put("referenceNumber", job.referenceNumber);
            payload.put("applicationEmail", job.applicationEmail);
            payload.put("applicationUrl", job.applicationUrl);
            payload.put("cvDraft", cvText == null ? "" : cvText);
            payload.put("coverLetterText", coverLetter == null ? "" : coverLetter);
            payload.put("emailBody", emailDraft == null ? "" : emailDraft);
            payload.put("matchScore", matchScore);
            payload.put("isAIGenerated", false);

            FirebaseFirestore.getInstance()
                    .collection("applications")
                    .document(user.getUid() + "_" + documentSafeId(jobKey(job)))
                    .set(payload, SetOptions.merge())
                    .addOnSuccessListener(unused -> completion.onComplete(true, "Application synced."))
                    .addOnFailureListener(failure -> completion.onComplete(false, failure.getLocalizedMessage()));
        });
    }

    void deleteApplication(String jobKey, Completion completion) {
        withUser((user, error) -> {
            if (user == null) {
                completion.onComplete(false, error);
                return;
            }

            FirebaseFirestore.getInstance()
                    .collection("applications")
                    .document(user.getUid() + "_" + documentSafeId(jobKey))
                    .delete()
                    .addOnSuccessListener(unused -> completion.onComplete(true, "Application deleted."))
                    .addOnFailureListener(failure -> completion.onComplete(false, failure.getLocalizedMessage()));
        });
    }

    void saveSavedJob(Job job, boolean saved, Completion completion) {
        withUser((user, error) -> {
            if (user == null) {
                completion.onComplete(false, error);
                return;
            }

            String documentId = user.getUid() + "_" + documentSafeId(jobKey(job));
            if (!saved) {
                FirebaseFirestore.getInstance()
                        .collection("savedJobs")
                        .document(documentId)
                        .delete()
                        .addOnSuccessListener(unused -> completion.onComplete(true, "Saved job removed."))
                        .addOnFailureListener(failure -> completion.onComplete(false, failure.getLocalizedMessage()));
                return;
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("userId", user.getUid());
            payload.put("jobKey", jobKey(job));
            payload.put("jobTitle", job.title);
            payload.put("companyName", job.company);
            payload.put("applicationMethod", job.method);
            payload.put("savedDate", System.currentTimeMillis());

            FirebaseFirestore.getInstance()
                    .collection("savedJobs")
                    .document(documentId)
                    .set(payload, SetOptions.merge())
                    .addOnSuccessListener(unused -> completion.onComplete(true, "Saved job synced."))
                    .addOnFailureListener(failure -> completion.onComplete(false, failure.getLocalizedMessage()));
        });
    }

    private void withUser(UserCallback callback) {
        if (!isConfigured()) {
            callback.onUser(null, "Firebase is not configured on this Android build.");
            return;
        }

        FirebaseUser currentUser = FirebaseAuth.getInstance().getCurrentUser();
        if (currentUser != null) {
            callback.onUser(currentUser, null);
            return;
        }

        FirebaseAuth.getInstance()
                .signInAnonymously()
                .addOnSuccessListener(result -> callback.onUser(result.getUser(), null))
                .addOnFailureListener(error -> callback.onUser(null, error.getLocalizedMessage()));
    }

    private interface UserCallback {
        void onUser(FirebaseUser user, String error);
    }

    private String jobKey(Job job) {
        return (job.title + "|" + job.company).toLowerCase();
    }

    private String documentSafeId(String value) {
        return value == null ? "unknown" : value.replaceAll("[^a-zA-Z0-9_-]", "_");
    }
}
