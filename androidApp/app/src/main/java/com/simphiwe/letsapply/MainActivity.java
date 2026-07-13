package com.simphiwe.letsapply;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.List;

public final class MainActivity extends Activity {
    private static final int GREEN = Color.rgb(11, 127, 80);
    private static final int LIGHT_GREEN = Color.rgb(232, 246, 238);
    private static final int INK = Color.rgb(17, 24, 39);
    private static final int MUTED = Color.rgb(118, 126, 132);
    private static final int SURFACE = Color.rgb(247, 250, 248);

    private final JobRepository repository = new JobRepository();
    private FirestoreJobRepository firestoreRepository;
    private LinearLayout root;
    private LinearLayout content;
    private String currentTab = "Home";
    private String selectedFilter = "All";
    private String searchText = "";
    private boolean guestMode = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        firestoreRepository = new FirestoreJobRepository(this);
        fetchJobs();
        showOnboarding();
    }

    private void fetchJobs() {
        firestoreRepository.fetchPublishedJobs(new JobLoadCallback() {
            @Override
            public void onJobsLoaded(List<Job> jobs) {
                repository.replaceJobs(jobs);
                if (content != null) {
                    runOnUiThread(() -> showMain(currentTab));
                }
            }

            @Override
            public void onFallbackRequired(String reason) {
                // Keep the local preview jobs until Firebase Android setup is complete.
            }
        });
    }

    private void showOnboarding() {
        root = vertical();
        root.setBackgroundColor(Color.WHITE);
        root.setPadding(dp(24), dp(48), dp(24), dp(24));
        setContentView(root);

        TextView appName = label("Let's Apply", 26, INK, Typeface.BOLD);
        appName.setGravity(Gravity.CENTER);
        root.addView(appName, matchWrap());

        TextView panel = label("Career intelligence, ready when you are.", 34, Color.WHITE, Typeface.BOLD);
        panel.setGravity(Gravity.BOTTOM | Gravity.LEFT);
        panel.setPadding(dp(22), dp(20), dp(22), dp(24));
        panel.setBackground(rounded(Color.rgb(4, 20, 25), 14));
        panel.setElevation(dp(2));
        LinearLayout.LayoutParams panelParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(260)
        );
        panelParams.setMargins(0, dp(80), 0, dp(28));
        root.addView(panel, panelParams);

        TextView createProfile = button("Create Profile", GREEN, Color.WHITE);
        createProfile.setOnClickListener(view -> {
            guestMode = false;
            showMain("Home");
        });
        root.addView(createProfile, matchHeight(dp(58)));

        TextView guest = label("Explore as Guest", 20, GREEN, Typeface.BOLD);
        guest.setGravity(Gravity.CENTER);
        guest.setPadding(0, dp(24), 0, dp(12));
        guest.setOnClickListener(view -> {
            guestMode = true;
            showMain("Home");
        });
        root.addView(guest, matchWrap());
    }

    private void showMain(String tab) {
        currentTab = tab;
        root = vertical();
        root.setBackgroundColor(SURFACE);
        setContentView(root);

        content = vertical();
        FrameLayout frame = new FrameLayout(this);
        frame.addView(content);
        root.addView(frame, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1
        ));

        LinearLayout nav = horizontal();
        nav.setGravity(Gravity.CENTER);
        nav.setBackgroundColor(Color.WHITE);
        nav.setPadding(dp(12), dp(10), dp(12), dp(16));
        root.addView(nav, matchHeight(dp(86)));

        addNavItem(nav, "Home", tab);
        addNavItem(nav, "Jobs", tab);
        addNavItem(nav, "Profile", tab);

        if ("Jobs".equals(tab)) {
            renderJobs();
        } else if ("Profile".equals(tab)) {
            renderProfile();
        } else {
            renderHome();
        }
    }

    private void addNavItem(LinearLayout nav, String title, String current) {
        TextView item = label(title, 16, title.equals(current) ? GREEN : INK, Typeface.BOLD);
        item.setGravity(Gravity.CENTER);
        item.setOnClickListener(view -> showMain(title));
        nav.addView(item, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1));
    }

    private void renderHome() {
        content.removeAllViews();
        content.setPadding(dp(22), dp(44), dp(22), 0);

        TextView title = label("Let's Apply", 28, INK, Typeface.BOLD);
        content.addView(title, matchWrap());

        TextView banner = label("Find better vacancies. Prepare stronger applications. Stay in control.", 27, Color.WHITE, Typeface.BOLD);
        banner.setPadding(dp(20), dp(22), dp(20), dp(22));
        banner.setBackgroundColor(GREEN);
        LinearLayout.LayoutParams bannerParams = matchHeight(dp(168));
        bannerParams.setMargins(0, dp(24), 0, dp(30));
        content.addView(banner, bannerParams);

        sectionTitle("Featured Jobs");
        addJobRow(repository.filter("", "Featured"), 2);

        sectionTitle("Recommended For You");
        addJobRow(repository.allJobs(), 3);
    }

    private void renderJobs() {
        content.removeAllViews();
        content.setPadding(dp(16), dp(42), dp(16), 0);

        TextView title = label("Jobs", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        content.addView(title, matchWrap());

        EditText search = new EditText(this);
        search.setHint("Search jobs, companies, skills");
        search.setSingleLine(true);
        search.setText(searchText);
        search.setTextSize(20);
        search.setPadding(dp(18), 0, dp(18), 0);
        search.setBackground(rounded(Color.WHITE, 28));
        search.setElevation(dp(2));
        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                searchText = s.toString();
                renderJobResults();
            }
            @Override public void afterTextChanged(Editable s) {}
        });
        LinearLayout.LayoutParams searchParams = matchHeight(dp(58));
        searchParams.setMargins(0, dp(24), 0, dp(16));
        content.addView(search, searchParams);

        addFilters();

        ScrollView scrollView = new ScrollView(this);
        LinearLayout results = vertical();
        results.setTag("jobResults");
        scrollView.addView(results);
        content.addView(scrollView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1
        ));

        renderJobResults();
    }

    private void addFilters() {
        HorizontalScrollView scroller = new HorizontalScrollView(this);
        scroller.setHorizontalScrollBarEnabled(false);
        LinearLayout row = horizontal();
        row.setPadding(0, 0, 0, dp(14));
        scroller.addView(row);
        content.addView(scroller, matchWrap());

        String[] filters = {"All", "Remote", "Featured", "Government", "Permanent", "Contract"};
        for (String filter : filters) {
            TextView chip = label(filter, 15, selectedFilter.equals(filter) ? Color.WHITE : GREEN, Typeface.BOLD);
            chip.setGravity(Gravity.CENTER);
            chip.setPadding(dp(18), dp(10), dp(18), dp(10));
            chip.setBackground(rounded(selectedFilter.equals(filter) ? GREEN : LIGHT_GREEN, 22));
            chip.setOnClickListener(view -> {
                selectedFilter = filter;
                renderJobs();
            });
            LinearLayout.LayoutParams chipParams = wrapWrap();
            chipParams.setMargins(0, 0, dp(10), 0);
            row.addView(chip, chipParams);
        }
    }

    private void renderJobResults() {
        LinearLayout results = content.findViewWithTag("jobResults");
        if (results == null) {
            return;
        }

        results.removeAllViews();
        List<Job> jobs = repository.filter(searchText, selectedFilter);
        if (jobs.isEmpty()) {
            TextView empty = label("No jobs found yet.", 18, MUTED, Typeface.BOLD);
            empty.setGravity(Gravity.CENTER);
            results.addView(empty, matchHeight(dp(260)));
            return;
        }

        for (Job job : jobs) {
            results.addView(jobCard(job), cardParams());
        }
    }

    private void renderProfile() {
        content.removeAllViews();
        content.setPadding(dp(22), dp(44), dp(22), 0);

        TextView title = label("Profile", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        content.addView(title, matchWrap());

        TextView profile = label(
                guestMode
                        ? "Guest profile\nCreate a profile to save jobs, generate documents, and apply."
                        : "Reuben Simphiwe Kuse\nSoftware Developer\nDurban\nProfile 100% complete",
                22,
                INK,
                Typeface.BOLD
        );
        profile.setPadding(dp(20), dp(24), dp(20), dp(24));
        applyCardStyle(profile);
        LinearLayout.LayoutParams profileParams = cardParams();
        profileParams.setMargins(0, dp(28), 0, dp(18));
        content.addView(profile, profileParams);

        TextView cv = button("CV Studio", LIGHT_GREEN, GREEN);
        content.addView(cv, cardParams());

        TextView applications = button("My Applications", LIGHT_GREEN, GREEN);
        content.addView(applications, cardParams());
    }

    private View jobCard(Job job) {
        LinearLayout card = vertical();
        card.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(card);
        card.setOnClickListener(view -> showJobDetails(job));

        TextView source = label(job.source, 14, GREEN, Typeface.BOLD);
        card.addView(source, matchWrap());

        TextView title = label(job.title, 22, INK, Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(14), 0, dp(8));
        card.addView(title, titleParams);

        card.addView(label(job.company, 17, MUTED, Typeface.BOLD), matchWrap());
        card.addView(label(job.location, 16, MUTED, Typeface.NORMAL), matchWrap());

        TextView salary = label(SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod), 17, INK, Typeface.BOLD);
        LinearLayout.LayoutParams salaryParams = matchWrap();
        salaryParams.setMargins(0, dp(14), 0, 0);
        card.addView(salary, salaryParams);

        return card;
    }

    private void showJobDetails(Job job) {
        content.removeAllViews();
        content.setPadding(dp(20), dp(42), dp(20), dp(20));

        TextView back = label("< Jobs", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Jobs"));
        content.addView(back, matchWrap());

        TextView title = label(job.title, 30, INK, Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(28), 0, dp(10));
        content.addView(title, titleParams);

        TextView meta = label(
                job.company + "\n" + job.location + "\n" + SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod),
                18,
                MUTED,
                Typeface.BOLD
        );
        content.addView(meta, matchWrap());

        addDetailsSection("Description", job.description);
        addDetailsSection("Requirements", job.requirements);
        addDetailsSection("How You Will Apply", applicationCopy(job));

        TextView submit = button("Submit Application", GREEN, Color.WHITE);
        submit.setOnClickListener(view -> handleApply(job));
        LinearLayout.LayoutParams submitParams = matchHeight(dp(62));
        submitParams.setMargins(0, dp(20), 0, dp(22));
        content.addView(submit, submitParams);
    }

    private void handleApply(Job job) {
        if (guestMode) {
            new AlertDialog.Builder(this)
                    .setTitle("Create your profile")
                    .setMessage("Create your profile to submit applications.")
                    .setPositiveButton("Create Profile", (dialog, which) -> {
                        guestMode = false;
                        showMain("Profile");
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Review before submitting")
                .setMessage("Let’s Apply will prepare your profile, CV draft, cover letter, and application instructions before you leave the app.")
                .setPositiveButton("Continue", (dialog, which) -> routeApplication(job))
                .setNegativeButton("Cancel", null)
                .show();
    }

    private String applicationCopy(Job job) {
        switch (job.method) {
            case "email":
                return "Let’s Apply prepares your CV, cover letter, and email draft. You review and send from your email app.";
            case "externalWebsite":
                return "Let’s Apply prepares your documents, then opens the employer website so you can attach them manually.";
            case "governmentEmail":
                return "Let’s Apply prepares your CV, cover letter, Z83 checklist, and government email package.";
            default:
                return "Let’s Apply submits inside the app and stores the application status.";
        }
    }

    private String applicationAction(Job job) {
        switch (job.method) {
            case "email":
                return "Next Android phase will open a pre-filled email composer with generated documents.";
            case "externalWebsite":
                return "Next Android phase will open the employer website after document export.";
            case "governmentEmail":
                return "Next Android phase will attach the CV, cover letter, and Z83 package.";
            default:
                return "Application tracking will be saved to Firestore once Firebase Android is connected.";
        }
    }

    private void routeApplication(Job job) {
        if ("email".equals(job.method) || "governmentEmail".equals(job.method)) {
            openEmailApplication(job);
            return;
        }

        if ("externalWebsite".equals(job.method) || "governmentWebsite".equals(job.method)) {
            openApplicationWebsite(job);
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Application submitted")
                .setMessage("This vacancy can be submitted inside Let’s Apply. Firestore application tracking will be enabled after Firebase Android setup.")
                .setPositiveButton("OK", null)
                .show();
    }

    private void openEmailApplication(Job job) {
        if (job.applicationEmail == null || job.applicationEmail.trim().isEmpty()) {
            showMissingApplicationContact(job);
            return;
        }

        String subject = "Application: " + job.title + referenceSuffix(job);
        String body = "Dear Hiring Manager,\n\n"
                + "Please find my application for the " + job.title + " position at " + job.company + ".\n\n"
                + "Let’s Apply will attach the generated CV, cover letter, and required forms in the next Android phase. For now, please attach the exported documents before sending.\n\n"
                + "Kind regards";

        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:" + Uri.encode(job.applicationEmail.trim())));
        intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        intent.putExtra(Intent.EXTRA_TEXT, body);

        if (intent.resolveActivity(getPackageManager()) == null) {
            showMissingEmailApp(job);
            return;
        }

        startActivity(intent);
    }

    private void openApplicationWebsite(Job job) {
        if (job.applicationUrl == null || job.applicationUrl.trim().isEmpty()) {
            showMissingApplicationContact(job);
            return;
        }

        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(job.applicationUrl.trim()));
        if (intent.resolveActivity(getPackageManager()) == null) {
            new AlertDialog.Builder(this)
                    .setTitle("Could not open website")
                    .setMessage(job.applicationUrl)
                    .setPositiveButton("OK", null)
                    .show();
            return;
        }

        startActivity(intent);
    }

    private void showMissingEmailApp(Job job) {
        new AlertDialog.Builder(this)
                .setTitle("Email app not available")
                .setMessage("Send your application to:\n\n" + job.applicationEmail + "\n\nSubject:\nApplication: " + job.title + referenceSuffix(job))
                .setPositiveButton("OK", null)
                .show();
    }

    private void showMissingApplicationContact(Job job) {
        new AlertDialog.Builder(this)
                .setTitle("Application destination missing")
                .setMessage("This vacancy needs an application email or website before Let’s Apply can route the submission.")
                .setPositiveButton("OK", null)
                .show();
    }

    private String referenceSuffix(Job job) {
        if (job.referenceNumber == null || job.referenceNumber.trim().isEmpty()) {
            return "";
        }
        return " - Ref " + job.referenceNumber.trim();
    }

    private void addDetailsSection(String heading, String body) {
        TextView section = label(heading + "\n\n" + body, 18, INK, Typeface.BOLD);
        section.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(section);
        LinearLayout.LayoutParams params = cardParams();
        params.setMargins(0, dp(18), 0, 0);
        content.addView(section, params);
    }

    private void sectionTitle(String title) {
        TextView view = label(title, 24, INK, Typeface.BOLD);
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, 0, 0, dp(14));
        content.addView(view, params);
    }

    private void addJobRow(List<Job> jobs, int limit) {
        LinearLayout row = horizontal();
        for (int index = 0; index < jobs.size() && index < limit; index++) {
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(210), 1);
            params.setMargins(0, 0, dp(10), dp(26));
            row.addView(jobCard(jobs.get(index)), params);
        }
        content.addView(row, matchWrap());
    }

    private TextView label(String text, int sp, int color, int style) {
        TextView label = new TextView(this);
        label.setText(text);
        label.setTextSize(sp);
        label.setTextColor(color);
        label.setTypeface(Typeface.DEFAULT, style);
        label.setIncludeFontPadding(true);
        return label;
    }

    private TextView button(String text, int background, int foreground) {
        TextView button = label(text, 19, foreground, Typeface.BOLD);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(16), 0, dp(16), 0);
        button.setBackground(rounded(background, 16));
        button.setElevation(dp(1));
        return button;
    }

    private LinearLayout vertical() {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        return layout;
    }

    private LinearLayout horizontal() {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.HORIZONTAL);
        return layout;
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
    }

    private LinearLayout.LayoutParams matchHeight(int height) {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                height
        );
    }

    private LinearLayout.LayoutParams wrapWrap() {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
    }

    private LinearLayout.LayoutParams cardParams() {
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, 0, 0, dp(14));
        return params;
    }

    private int dp(int value) {
        float density = getResources().getDisplayMetrics().density;
        return Math.round(value * density);
    }

    private void applyCardStyle(View view) {
        view.setBackground(rounded(Color.WHITE, 14));
        view.setElevation(dp(1));
    }

    private GradientDrawable rounded(int color, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(radius));
        drawable.setStroke(dp(1), Color.rgb(216, 230, 222));
        return drawable;
    }
}
