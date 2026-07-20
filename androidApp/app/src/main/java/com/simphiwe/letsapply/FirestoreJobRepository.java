package com.simphiwe.letsapply;

import android.content.Context;
import android.util.Log;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.Timestamp;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Locale;

final class FirestoreJobRepository {
    private static final String TAG = "LetsApplyJobs";

    private final Context context;

    FirestoreJobRepository(Context context) {
        this.context = context.getApplicationContext();
    }

    boolean isConfigured() {
        return !FirebaseApp.getApps(context).isEmpty();
    }

    void fetchPublishedJobs(JobLoadCallback callback) {
        Log.d(TAG, "Firebase app count: " + FirebaseApp.getApps(context).size());
        if (!isConfigured()) {
            Log.w(TAG, "Firebase is not configured for Android yet.");
            callback.onFallbackRequired("Add google-services.json to load Firebase jobs.");
            return;
        }

        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) {
            auth.signInAnonymously()
                    .addOnSuccessListener(result -> {
                        Log.d(TAG, "Anonymous Firebase auth succeeded.");
                        fetchPublishedJobsAfterAuth(callback);
                    })
                    .addOnFailureListener(error -> {
                        Log.w(TAG, "Anonymous Firebase auth failed.", error);
                        callback.onFallbackRequired(error.getLocalizedMessage());
                    });
            return;
        }

        fetchPublishedJobsAfterAuth(callback);
    }

    private void fetchPublishedJobsAfterAuth(JobLoadCallback callback) {
        FirebaseFirestore.getInstance()
                .collection("jobs")
                .whereEqualTo("publicationStatus", "published")
                .limit(1000)
                .get()
                .addOnSuccessListener(snapshot -> {
                    List<Job> jobs = new ArrayList<>();
                    Set<String> seenDocumentIds = new HashSet<>();
                    for (DocumentSnapshot document : snapshot.getDocuments()) {
                        if (isCandidateVisible(document)) {
                            jobs.add(mapJob(document));
                            seenDocumentIds.add(document.getId());
                        }
                    }
                    Log.d(TAG, "Modern published jobs loaded: " + jobs.size());
                    fetchLegacyPublishedJobs(callback, jobs, seenDocumentIds);
                })
                .addOnFailureListener(error -> {
                    Log.w(TAG, "Modern published jobs query failed.", error);
                    callback.onFallbackRequired(error.getLocalizedMessage());
                });
    }

    private void fetchLegacyPublishedJobs(JobLoadCallback callback, List<Job> jobs, Set<String> seenDocumentIds) {
        FirebaseFirestore.getInstance()
                .collection("jobs")
                .whereEqualTo("visibility", "published")
                .limit(200)
                .get()
                .addOnSuccessListener(snapshot -> {
                    for (DocumentSnapshot document : snapshot.getDocuments()) {
                        if (!seenDocumentIds.contains(document.getId()) && isCandidateVisible(document)) {
                            jobs.add(mapJob(document));
                        }
                    }
                    Log.d(TAG, "Total candidate-visible jobs loaded: " + jobs.size());
                    callback.onJobsLoaded(jobs);
                })
                .addOnFailureListener(error -> {
                    Log.w(TAG, "Legacy published jobs query failed. Continuing with modern jobs.", error);
                    callback.onJobsLoaded(jobs);
                });
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

        String company = firstString(
                documentString(document, "companyName"),
                documentString(document, "company_name"),
                "Company not listed"
        );
        String source = firstString(documentString(document, "sourceName"), documentString(document, "sourceType"), "Let’s Apply");
        String applicationEmail = firstString(
                documentString(document, "applicationEmail"),
                application == null ? null : stringValue(application.get("applicationEmail")),
                application == null ? null : stringValue(application.get("email")),
                application == null ? null : stringValue(application.get("application_email")),
                ""
        );
        String applicationUrl = firstString(
                documentString(document, "applicationUrl"),
                application == null ? null : stringValue(application.get("applicationUrl")),
                application == null ? null : stringValue(application.get("url")),
                application == null ? null : stringValue(application.get("applicationLink")),
                application == null ? null : stringValue(application.get("application_url")),
                ""
        );
        String method = firstString(
                documentString(document, "applicationMethod"),
                application == null ? null : stringValue(application.get("method")),
                inferredMethod(company, source, applicationEmail, applicationUrl)
        );
        String referenceNumber = firstString(
                documentString(document, "referenceNumber"),
                application == null ? null : stringValue(application.get("referenceNumber")),
                application == null ? null : stringValue(application.get("reference")),
                ""
        );
        String salaryPeriod = firstString(
                documentString(document, "salaryPeriod"),
                salaryRange == null ? null : stringValue(salaryRange.get("period")),
                compensation == null ? null : stringValue(compensation.get("period")),
                "per annum"
        );
        Object visibility = document.get("visibility");
        boolean featured = booleanValue(document.get("featured"))
                || (visibility instanceof Map && booleanValue(((Map<String, Object>) visibility).get("featured")));

        return new Job(
                firstString(documentString(document, "title"), "Untitled vacancy"),
                company,
                locationText(document),
                firstString(documentString(document, "jobType"), "Full-time"),
                method,
                source,
                applicationEmail,
                applicationUrl,
                referenceNumber,
                firstString(
                        documentString(document, "description"),
                        documentString(document, "duties"),
                        documentString(document, "responsibilities"),
                        "No description supplied yet."
                ),
                firstString(
                        documentString(document, "requirements"),
                        documentString(document, "qualifications"),
                        "Requirements not listed."
                ),
                salaryRange == null ? firstString(documentString(document, "currency"), "ZAR") : firstString(stringValue(salaryRange.get("currency")), "ZAR"),
                salaryRange == null ? numberValue(document.get("salaryMin")) : numberValue(salaryRange.get("min")),
                salaryRange == null ? numberValue(document.get("salaryMax")) : numberValue(salaryRange.get("max")),
                salaryPeriod,
                booleanValue(document.get("remote")),
                featured
        );
    }

    private String firstString(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private boolean isCandidateVisible(DocumentSnapshot document) {
        String status = firstString(
                documentString(document, "publicationStatus"),
                documentString(document, "status"),
                ""
        ).toLowerCase(Locale.ROOT);
        Object visibility = document.get("visibility");
        boolean legacyPublished = visibility instanceof String
                && "published".equalsIgnoreCase((String) visibility);
        boolean published = "published".equals(status) || legacyPublished;

        return published && !isExpired(document);
    }

    private boolean isExpired(DocumentSnapshot document) {
        Map<String, Object> application = document.get("application") instanceof Map
                ? (Map<String, Object>) document.get("application")
                : null;
        Date closingDate = dateValue(
                document.get("closingDate") != null
                        ? document.get("closingDate")
                        : application == null ? null : application.get("closingDate")
        );

        if (closingDate == null) {
            return false;
        }

        Calendar today = Calendar.getInstance();
        today.set(Calendar.HOUR_OF_DAY, 0);
        today.set(Calendar.MINUTE, 0);
        today.set(Calendar.SECOND, 0);
        today.set(Calendar.MILLISECOND, 0);

        return closingDate.before(today.getTime());
    }

    private Date dateValue(Object value) {
        if (value instanceof Timestamp) {
            return ((Timestamp) value).toDate();
        }

        if (value instanceof Date) {
            return (Date) value;
        }

        if (value == null) {
            return null;
        }

        String rawValue = String.valueOf(value).trim();
        if (rawValue.isEmpty()) {
            return null;
        }

        String[] patterns = {
                "yyyy-MM-dd",
                "yyyy/MM/dd",
                "dd MMM yyyy",
                "d MMM yyyy",
                "MMMM d, yyyy"
        };

        for (String pattern : patterns) {
            try {
                SimpleDateFormat formatter = new SimpleDateFormat(pattern, Locale.US);
                formatter.setLenient(false);
                return formatter.parse(rawValue);
            } catch (ParseException ignored) {
                // Try the next known Firestore/import date format.
            }
        }

        return null;
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

    private String firstString(String first, String second, String third, String fallback) {
        if (first != null && !first.trim().isEmpty()) {
            return first.trim();
        }
        if (second != null && !second.trim().isEmpty()) {
            return second.trim();
        }
        if (third != null && !third.trim().isEmpty()) {
            return third.trim();
        }
        return fallback;
    }

    private String firstString(String first, String second, String third, String fourth, String fallback) {
        if (first != null && !first.trim().isEmpty()) {
            return first.trim();
        }
        if (second != null && !second.trim().isEmpty()) {
            return second.trim();
        }
        if (third != null && !third.trim().isEmpty()) {
            return third.trim();
        }
        if (fourth != null && !fourth.trim().isEmpty()) {
            return fourth.trim();
        }
        return fallback;
    }

    private String firstString(String first, String second, String third, String fourth, String fifth, String fallback) {
        if (first != null && !first.trim().isEmpty()) {
            return first.trim();
        }
        if (second != null && !second.trim().isEmpty()) {
            return second.trim();
        }
        if (third != null && !third.trim().isEmpty()) {
            return third.trim();
        }
        if (fourth != null && !fourth.trim().isEmpty()) {
            return fourth.trim();
        }
        if (fifth != null && !fifth.trim().isEmpty()) {
            return fifth.trim();
        }
        return fallback;
    }

    private String inferredMethod(String company, String source, String email, String url) {
        String haystack = (company + " " + source).toLowerCase();
        boolean government = haystack.contains("dpsa")
                || haystack.contains("department of")
                || haystack.contains("public service");

        if (email != null && !email.trim().isEmpty()) {
            return government ? "governmentEmail" : "email";
        }
        if (url != null && !url.trim().isEmpty()) {
            return government ? "governmentWebsite" : "externalWebsite";
        }
        return government ? "governmentManual" : "internalApply";
    }

    private String documentString(DocumentSnapshot document, String field) {
        return stringValue(document.get(field));
    }

    private String locationText(DocumentSnapshot document) {
        Object value = document.get("location");
        if (value instanceof Map) {
            Map<String, Object> location = (Map<String, Object>) value;
            List<String> parts = new ArrayList<>();
            addUniquePart(parts, stringValue(location.get("city")));
            addUniquePart(parts, stringValue(location.get("province")));
            addUniquePart(parts, stringValue(location.get("region")));
            addUniquePart(parts, stringValue(location.get("country")));
            if (!parts.isEmpty()) {
                return String.join(", ", parts);
            }
        }

        return firstString(
                stringValue(value),
                documentString(document, "city"),
                documentString(document, "province"),
                "Location not listed"
        );
    }

    private void addUniquePart(List<String> parts, String value) {
        if (value == null || value.trim().isEmpty()) {
            return;
        }

        String cleaned = value.trim();
        for (String part : parts) {
            if (part.equalsIgnoreCase(cleaned)) {
                return;
            }
        }
        parts.add(cleaned);
    }

    private String stringValue(Object value) {
        if (value == null) {
            return null;
        }

        if (value instanceof String) {
            String cleaned = ((String) value).trim();
            return cleaned.isEmpty() ? null : cleaned;
        }

        if (value instanceof List) {
            List<?> values = (List<?>) value;
            List<String> lines = new ArrayList<>();
            for (Object item : values) {
                String line = stringValue(item);
                if (line != null && !line.trim().isEmpty()) {
                    lines.add(line.trim());
                }
            }
            return lines.isEmpty() ? null : String.join("\n", lines);
        }

        if (value instanceof Map) {
            Map<?, ?> map = (Map<?, ?>) value;
            for (String key : new String[]{"text", "value", "description", "title", "name", "email", "url", "method", "referenceNumber"}) {
                if (map.containsKey(key)) {
                    String nested = stringValue(map.get(key));
                    if (nested != null && !nested.trim().isEmpty()) {
                        return nested.trim();
                    }
                }
            }
            return null;
        }

        String cleaned = String.valueOf(value).trim();
        return cleaned.isEmpty() ? null : cleaned;
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
        if (value instanceof Boolean) {
            return (Boolean) value;
        }

        if (value instanceof Number) {
            return ((Number) value).intValue() != 0;
        }

        if (value instanceof String) {
            String normalized = ((String) value).trim().toLowerCase(Locale.ROOT);
            return normalized.equals("true") || normalized.equals("yes") || normalized.equals("1");
        }

        return false;
    }
}
