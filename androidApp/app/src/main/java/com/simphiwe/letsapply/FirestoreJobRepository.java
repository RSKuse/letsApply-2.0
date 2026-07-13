package com.simphiwe.letsapply;

import android.content.Context;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

final class FirestoreJobRepository {
    private final Context context;

    FirestoreJobRepository(Context context) {
        this.context = context.getApplicationContext();
    }

    boolean isConfigured() {
        return !FirebaseApp.getApps(context).isEmpty();
    }

    void fetchPublishedJobs(JobLoadCallback callback) {
        if (!isConfigured()) {
            callback.onFallbackRequired("Add google-services.json to load Firebase jobs.");
            return;
        }

        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) {
            auth.signInAnonymously()
                    .addOnSuccessListener(result -> fetchPublishedJobsAfterAuth(callback))
                    .addOnFailureListener(error -> callback.onFallbackRequired(error.getLocalizedMessage()));
            return;
        }

        fetchPublishedJobsAfterAuth(callback);
    }

    private void fetchPublishedJobsAfterAuth(JobLoadCallback callback) {

        FirebaseFirestore.getInstance()
                .collection("jobs")
                .whereEqualTo("visibility", "published")
                .orderBy("closingDate", Query.Direction.ASCENDING)
                .limit(100)
                .get()
                .addOnSuccessListener(snapshot -> {
                    List<Job> jobs = new ArrayList<>();
                    for (DocumentSnapshot document : snapshot.getDocuments()) {
                        jobs.add(mapJob(document));
                    }
                    callback.onJobsLoaded(jobs);
                })
                .addOnFailureListener(error -> callback.onFallbackRequired(error.getLocalizedMessage()));
    }

    private Job mapJob(DocumentSnapshot document) {
        Map<String, Object> compensation = document.get("compensation") instanceof Map
                ? (Map<String, Object>) document.get("compensation")
                : null;
        Map<String, Object> salaryRange = compensation != null && compensation.get("salaryRange") instanceof Map
                ? (Map<String, Object>) compensation.get("salaryRange")
                : null;
        Map<String, Object> application = document.get("application") instanceof Map
                ? (Map<String, Object>) document.get("application")
                : null;

        String method = firstString(
                document.getString("applicationMethod"),
                application == null ? null : stringValue(application.get("method")),
                "internalApply"
        );

        String company = firstString(
                document.getString("companyName"),
                document.getString("company_name"),
                "Company not listed"
        );

        return new Job(
                firstString(document.getString("title"), "Untitled vacancy"),
                company,
                firstString(document.getString("location"), "Location not listed"),
                firstString(document.getString("jobType"), "Full-time"),
                method,
                firstString(document.getString("sourceName"), document.getString("sourceType"), "Let’s Apply"),
                firstString(
                        document.getString("applicationEmail"),
                        application == null ? null : stringValue(application.get("applicationEmail")),
                        ""
                ),
                firstString(
                        document.getString("applicationUrl"),
                        application == null ? null : stringValue(application.get("applicationUrl")),
                        ""
                ),
                firstString(document.getString("referenceNumber"), ""),
                firstString(document.getString("description"), "No description supplied yet."),
                firstString(document.getString("requirements"), document.getString("qualifications"), "Requirements not listed."),
                salaryRange == null ? firstString(document.getString("currency"), "ZAR") : firstString(stringValue(salaryRange.get("currency")), "ZAR"),
                salaryRange == null ? numberValue(document.get("salaryMin")) : numberValue(salaryRange.get("min")),
                salaryRange == null ? numberValue(document.get("salaryMax")) : numberValue(salaryRange.get("max")),
                firstString(document.getString("salaryPeriod"), "per annum"),
                booleanValue(document.get("remote")),
                booleanValue(document.get("featured"))
        );
    }

    private String firstString(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private String firstString(String first, String second, String fallback) {
        if (first != null && !first.trim().isEmpty()) {
            return first.trim();
        }
        if (second != null && !second.trim().isEmpty()) {
            return second.trim();
        }
        return fallback;
    }

    private String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private int numberValue(Object value) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }

        if (value instanceof String) {
            try {
                return Integer.parseInt(((String) value).replaceAll("[^0-9]", ""));
            } catch (NumberFormatException ignored) {
                return 0;
            }
        }

        return 0;
    }

    private boolean booleanValue(Object value) {
        return value instanceof Boolean && (Boolean) value;
    }
}
