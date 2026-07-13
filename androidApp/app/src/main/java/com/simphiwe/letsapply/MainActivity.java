package com.simphiwe.letsapply;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.text.Editable;
import android.text.TextWatcher;

import java.util.List;
import java.util.Locale;

public final class MainActivity extends Activity {
    private static final int GREEN = Color.rgb(11, 127, 80);
    private static final int DARK_GREEN = Color.rgb(4, 82, 54);
    private static final int MINT = Color.rgb(232, 246, 238);
    private static final int INK = Color.rgb(17, 24, 39);
    private static final int MUTED = Color.rgb(116, 124, 130);
    private static final int SURFACE = Color.rgb(246, 251, 248);
    private static final int BORDER = Color.rgb(216, 230, 222);
    private static final int DARK_CARD = Color.rgb(4, 20, 25);
    private static final int AMBER = Color.rgb(255, 244, 230);
    private static final int ORANGE = Color.rgb(221, 111, 31);

    private final JobRepository repository = new JobRepository();
    private FirestoreJobRepository firestoreRepository;

    private LinearLayout root;
    private FrameLayout screenFrame;
    private LinearLayout content;
    private String currentTab = "Home";
    private String selectedFilter = "All";
    private String searchText = "";
    private boolean guestMode = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        styleSystemBars();
        firestoreRepository = new FirestoreJobRepository(this);
        fetchJobs();
        showOnboarding();
    }

    private void styleSystemBars() {
        Window window = getWindow();
        window.setStatusBarColor(SURFACE);
        window.setNavigationBarColor(Color.WHITE);
        window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
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
                // Local preview jobs remain available while Firebase setup is being completed.
            }
        });
    }

    private void showOnboarding() {
        root = vertical();
        root.setBackgroundColor(Color.WHITE);
        root.setPadding(dp(24), dp(48), dp(24), dp(24));
        setContentView(root);

        LinearLayout header = horizontal();
        header.setGravity(Gravity.CENTER_VERTICAL);
        root.addView(header, matchWrap());

        TextView appName = label("Let's Apply", 26, INK, Typeface.BOLD);
        appName.setGravity(Gravity.CENTER);
        header.addView(appName, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

        TextView signIn = label("Sign In", 18, INK, Typeface.BOLD);
        signIn.setGravity(Gravity.CENTER);
        signIn.setPadding(dp(18), dp(10), dp(18), dp(10));
        signIn.setBackground(rounded(Color.WHITE, 24));
        signIn.setOnClickListener(view -> {
            guestMode = false;
            showMain("Profile");
        });
        header.addView(signIn, wrapWrap());

        LinearLayout hero = vertical();
        hero.setPadding(dp(22), dp(24), dp(22), dp(24));
        hero.setBackground(rounded(DARK_CARD, 18));
        hero.setElevation(dp(3));
        LinearLayout.LayoutParams heroParams = matchHeight(dp(300));
        heroParams.setMargins(0, dp(78), 0, dp(28));
        root.addView(hero, heroParams);

        TextView badge = label("SMART APPLICATION PACKAGE", 14, Color.rgb(54, 173, 184), Typeface.BOLD);
        badge.setGravity(Gravity.RIGHT);
        hero.addView(badge, matchWrap());

        TextView title = label("Career intelligence,\nready when you are.", 34, Color.WHITE, Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(90), 0, dp(16));
        hero.addView(title, titleParams);

        TextView steps = label("PROFILE  |  MATCH  |  REVIEW", 14, Color.rgb(157, 165, 170), Typeface.BOLD);
        hero.addView(steps, matchWrap());

        TextView createProfile = button("Create Profile", GREEN, Color.WHITE);
        createProfile.setOnClickListener(view -> {
            guestMode = false;
            showMain("Home");
        });
        root.addView(createProfile, matchHeight(dp(58)));

        TextView guest = label("Explore as Guest", 21, GREEN, Typeface.BOLD);
        guest.setGravity(Gravity.CENTER);
        guest.setPadding(0, dp(26), 0, dp(10));
        guest.setOnClickListener(view -> {
            guestMode = true;
            showMain("Home");
        });
        root.addView(guest, matchWrap());

        TextView note = label("Free to explore. Your approval always comes first.", 14, MUTED, Typeface.BOLD);
        note.setGravity(Gravity.CENTER);
        root.addView(note, matchWrap());
    }

    private void showMain(String tab) {
        currentTab = tab;
        root = vertical();
        root.setBackgroundColor(SURFACE);
        setContentView(root);

        screenFrame = new FrameLayout(this);
        root.addView(screenFrame, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1
        ));

        LinearLayout nav = horizontal();
        nav.setGravity(Gravity.CENTER);
        nav.setBackgroundColor(Color.WHITE);
        nav.setPadding(dp(16), dp(10), dp(16), dp(16));
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

    private void setScrollableContent(int horizontalPadding, int topPadding, int bottomPadding) {
        screenFrame.removeAllViews();
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(false);
        scroll.setClipToPadding(false);
        content = vertical();
        content.setPadding(dp(horizontalPadding), dp(topPadding), dp(horizontalPadding), dp(bottomPadding));
        scroll.addView(content, matchWrap());
        screenFrame.addView(scroll);
    }

    private void addNavItem(LinearLayout nav, String title, String current) {
        TextView item = label(title, 15, title.equals(current) ? GREEN : INK, Typeface.BOLD);
        item.setGravity(Gravity.CENTER);
        item.setBackground(title.equals(current) ? rounded(Color.rgb(232, 236, 234), 32) : null);
        item.setOnClickListener(view -> showMain(title));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1);
        params.setMargins(dp(4), 0, dp(4), 0);
        nav.addView(item, params);
    }

    private void renderHome() {
        setScrollableContent(20, 32, 34);

        TextView title = label("Let's Apply", 28, INK, Typeface.BOLD);
        content.addView(title, matchWrap());

        LinearLayout hero = vertical();
        hero.setPadding(dp(22), dp(24), dp(22), dp(24));
        hero.setBackground(roundedGradient(DARK_GREEN, Color.rgb(21, 156, 83), 22));
        hero.setElevation(dp(3));
        LinearLayout.LayoutParams heroParams = matchHeight(dp(210));
        heroParams.setMargins(0, dp(20), 0, dp(20));
        content.addView(hero, heroParams);

        TextView heroBadge = label("AI CAREER OS", 13, Color.rgb(203, 246, 221), Typeface.BOLD);
        hero.addView(heroBadge, matchWrap());

        TextView heroTitle = label("Apply smarter", 31, Color.WHITE, Typeface.BOLD);
        LinearLayout.LayoutParams heroTitleParams = matchWrap();
        heroTitleParams.setMargins(0, dp(34), 0, dp(8));
        hero.addView(heroTitle, heroTitleParams);

        TextView heroText = label("Browse jobs, prepare documents, and keep every application moving.", 17, Color.WHITE, Typeface.BOLD);
        hero.addView(heroText, matchWrap());

        addInsightStrip();
        sectionHeader("Featured Jobs", "See All", () -> {
            selectedFilter = "Featured";
            showMain("Jobs");
        });
        addHorizontalJobScroller(repository.filter("", "Featured"), 2);

        sectionHeader("Recommended For You", "See All", () -> {
            selectedFilter = "All";
            showMain("Jobs");
        });
        addVerticalJobs(repository.allJobs(), 4);

        addCareerTipCard();
    }

    private void addInsightStrip() {
        LinearLayout strip = horizontal();
        strip.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams params = matchHeight(dp(82));
        params.setMargins(0, 0, 0, dp(24));
        content.addView(strip, params);

        addMetric(strip, String.valueOf(repository.allJobs().size()), "Live jobs");
        addMetric(strip, guestMode ? "Guest" : "Ready", "Access");
        addMetric(strip, "AI", "Review");
    }

    private void addMetric(LinearLayout strip, String value, String title) {
        LinearLayout metric = vertical();
        metric.setGravity(Gravity.CENTER);
        metric.setBackground(rounded(Color.WHITE, 14));
        TextView valueView = label(value, 18, INK, Typeface.BOLD);
        valueView.setGravity(Gravity.CENTER);
        TextView titleView = label(title, 12, MUTED, Typeface.BOLD);
        titleView.setGravity(Gravity.CENTER);
        metric.addView(valueView, matchWrap());
        metric.addView(titleView, matchWrap());
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1);
        params.setMargins(dp(4), 0, dp(4), 0);
        strip.addView(metric, params);
    }

    private void renderJobs() {
        setScrollableContent(16, 30, 32);

        TextView title = label("Jobs", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        content.addView(title, matchWrap());

        EditText search = new EditText(this);
        search.setHint("Search jobs, companies, skills");
        search.setSingleLine(true);
        search.setText(searchText);
        search.setTextSize(18);
        search.setTextColor(INK);
        search.setHintTextColor(Color.rgb(145, 151, 156));
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

        TextView filterTitle = label(selectedFilter, 18, selectedFilter.equals("All") ? INK : GREEN, Typeface.BOLD);
        filterTitle.setGravity(Gravity.CENTER);
        filterTitle.setPadding(0, dp(12), 0, dp(14));
        filterTitle.setBackground(rounded(selectedFilter.equals("All") ? MINT : Color.WHITE, 12));
        LinearLayout.LayoutParams filterTitleParams = matchWrap();
        filterTitleParams.setMargins(0, 0, 0, dp(16));
        content.addView(filterTitle, filterTitleParams);

        LinearLayout results = vertical();
        results.setTag("jobResults");
        content.addView(results, matchWrap());

        renderJobResults();
    }

    private void addFilters() {
        HorizontalScrollView scroller = new HorizontalScrollView(this);
        scroller.setHorizontalScrollBarEnabled(false);
        LinearLayout row = horizontal();
        row.setPadding(0, 0, 0, dp(14));
        scroller.addView(row);
        content.addView(scroller, matchWrap());

        String[] filters = {"All", "Remote", "Hybrid", "Featured", "Public Service", "Permanent", "Contract"};
        for (String filter : filters) {
            TextView chip = label(filter, 15, selectedFilter.equals(filter) ? Color.WHITE : GREEN, Typeface.BOLD);
            chip.setGravity(Gravity.CENTER);
            chip.setPadding(dp(18), dp(10), dp(18), dp(10));
            chip.setBackground(rounded(selectedFilter.equals(filter) ? GREEN : MINT, 22));
            chip.setOnClickListener(view -> {
                selectedFilter = filter;
                showMain("Jobs");
            });
            LinearLayout.LayoutParams chipParams = wrapWrap();
            chipParams.setMargins(0, 0, dp(10), 0);
            row.addView(chip, chipParams);
        }
    }

    private void renderJobResults() {
        if (content == null) {
            return;
        }

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

        for (int index = 0; index < jobs.size(); index += 2) {
            LinearLayout row = horizontal();
            LinearLayout.LayoutParams rowParams = matchWrap();
            rowParams.setMargins(0, 0, 0, dp(12));
            results.addView(row, rowParams);

            addGridCard(row, jobs.get(index), true);
            if (index + 1 < jobs.size()) {
                addGridCard(row, jobs.get(index + 1), false);
            } else {
                View spacer = new View(this);
                row.addView(spacer, new LinearLayout.LayoutParams(0, 1, 1));
            }
        }
    }

    private void addGridCard(LinearLayout row, Job job, boolean left) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(260), 1);
        params.setMargins(left ? 0 : dp(6), 0, left ? dp(6) : 0, 0);
        row.addView(jobCard(job, true), params);
    }

    private void renderProfile() {
        setScrollableContent(22, 30, 34);

        TextView title = label(guestMode ? "Complete Profile" : "Profile", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        content.addView(title, matchWrap());

        LinearLayout header = horizontal();
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(dp(18), dp(20), dp(18), dp(20));
        applyCardStyle(header);
        LinearLayout.LayoutParams headerParams = cardParams();
        headerParams.setMargins(0, dp(24), 0, dp(18));
        content.addView(header, headerParams);

        TextView avatar = label(guestMode ? "G" : "R", 26, Color.WHITE, Typeface.BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(rounded(GREEN, 46));
        header.addView(avatar, new LinearLayout.LayoutParams(dp(76), dp(76)));

        TextView profile = label(
                guestMode
                        ? "Guest profile\nCreate a profile to save jobs, generate documents, and apply."
                        : "Reuben Simphiwe Kuse\nSoftware Developer\nDurban\nProfile 100% complete",
                20,
                INK,
                Typeface.BOLD
        );
        LinearLayout.LayoutParams profileTextParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        profileTextParams.setMargins(dp(16), 0, 0, 0);
        header.addView(profile, profileTextParams);

        addProfileStatusCard();

        TextView create = button(guestMode ? "Create Profile" : "Edit Profile", GREEN, Color.WHITE);
        create.setOnClickListener(view -> {
            guestMode = false;
            showMain("Profile");
        });
        content.addView(create, matchHeight(dp(58)));

        addProfileAction("CV Studio", "Build a clean CV, references, certificates, and job-ready sections.");
        addProfileAction("My Applications", "Track submitted, email, website, and government applications.");
        addProfileAction("Saved Jobs", "Keep vacancies ready for later review.");
    }

    private void addProfileStatusCard() {
        TextView status = label(
                guestMode
                        ? "Profile locked\nCreate your profile once. Let the app reuse it for applications."
                        : "Profile 100% complete\nYou can apply now. Android document generation is being upgraded to match iOS.",
                18,
                guestMode ? ORANGE : DARK_GREEN,
                Typeface.BOLD
        );
        status.setPadding(dp(18), dp(18), dp(18), dp(18));
        status.setBackground(rounded(guestMode ? AMBER : MINT, 16));
        LinearLayout.LayoutParams params = cardParams();
        params.setMargins(0, 0, 0, dp(20));
        content.addView(status, params);
    }

    private void addProfileAction(String title, String subtitle) {
        TextView action = label(title + "\n" + subtitle, 18, INK, Typeface.BOLD);
        action.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(action);
        content.addView(action, cardParams());
    }

    private View jobCard(Job job, boolean compact) {
        LinearLayout card = vertical();
        card.setPadding(dp(16), dp(16), dp(16), dp(16));
        applyCardStyle(card);
        card.setOnClickListener(view -> showJobDetails(job));

        LinearLayout top = horizontal();
        top.setGravity(Gravity.CENTER_VERTICAL);
        card.addView(top, matchWrap());

        top.addView(logoView(job, compact ? 15 : 18), new LinearLayout.LayoutParams(dp(58), dp(58)));

        TextView source = label(sourceLabel(job), compact ? 12 : 14, GREEN, Typeface.BOLD);
        source.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams sourceParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        sourceParams.setMargins(dp(12), 0, 0, 0);
        top.addView(source, sourceParams);

        TextView title = label(job.title, compact ? 18 : 22, INK, Typeface.BOLD);
        title.setMaxLines(compact ? 3 : 4);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(16), 0, dp(8));
        card.addView(title, titleParams);

        TextView company = label(job.company, compact ? 14 : 17, MUTED, Typeface.BOLD);
        company.setMaxLines(1);
        card.addView(company, matchWrap());

        TextView location = label(job.location, compact ? 13 : 16, MUTED, Typeface.NORMAL);
        location.setMaxLines(2);
        LinearLayout.LayoutParams locationParams = matchWrap();
        locationParams.setMargins(0, dp(8), 0, 0);
        card.addView(location, locationParams);

        TextView salary = label(SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod), compact ? 14 : 17, INK, Typeface.BOLD);
        LinearLayout.LayoutParams salaryParams = matchWrap();
        salaryParams.setMargins(0, dp(12), 0, 0);
        card.addView(salary, salaryParams);

        return card;
    }

    private void showJobDetails(Job job) {
        currentTab = "Jobs";
        setScrollableContent(20, 30, 30);

        TextView back = label("< Jobs", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Jobs"));
        content.addView(back, matchWrap());

        LinearLayout hero = vertical();
        hero.setPadding(dp(20), dp(22), dp(20), dp(22));
        hero.setBackground(rounded(Color.WHITE, 18));
        hero.setElevation(dp(2));
        LinearLayout.LayoutParams heroParams = cardParams();
        heroParams.setMargins(0, dp(18), 0, dp(18));
        content.addView(hero, heroParams);

        LinearLayout identityRow = horizontal();
        identityRow.setGravity(Gravity.CENTER_VERTICAL);
        hero.addView(identityRow, matchWrap());

        identityRow.addView(logoView(job, 18), new LinearLayout.LayoutParams(dp(64), dp(64)));

        TextView source = label(sourceLabel(job), 15, GREEN, Typeface.BOLD);
        source.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams sourceParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        sourceParams.setMargins(dp(14), 0, 0, 0);
        identityRow.addView(source, sourceParams);

        TextView title = label(job.title, 29, INK, Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(10));
        hero.addView(title, titleParams);

        TextView meta = label(
                job.company + "\n" + job.location + "\n" + SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod),
                17,
                MUTED,
                Typeface.BOLD
        );
        hero.addView(meta, matchWrap());

        addDetailsSection("Application Route", applicationCopy(job));
        addDetailsSection("Description", job.description);
        addDetailsSection("Requirements", job.requirements);
        addContactSection(job);

        TextView submit = button("Submit Application", GREEN, Color.WHITE);
        submit.setOnClickListener(view -> handleApply(job));
        LinearLayout.LayoutParams submitParams = matchHeight(dp(62));
        submitParams.setMargins(0, dp(8), 0, dp(18));
        content.addView(submit, submitParams);
    }

    private void handleApply(Job job) {
        if (guestMode) {
            new AlertDialog.Builder(this)
                    .setTitle("Create your profile")
                    .setMessage("Create your profile to submit applications. Guests can browse, but applications need a profile.")
                    .setPositiveButton("Create Profile", (dialog, which) -> {
                        guestMode = false;
                        showMain("Profile");
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
            return;
        }

        showApplicationReview(job);
    }

    private void showApplicationReview(Job job) {
        setScrollableContent(20, 30, 34);

        TextView back = label("< Job Details", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showJobDetails(job));
        content.addView(back, matchWrap());

        TextView title = label("Review Application", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        addDetailsSection("Application Details", job.title + "\n" + job.company + "\n" + job.location + "\n" + SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod));
        addDetailsSection("How You'll Apply", applicationCopy(job));
        addDetailsSection("Required Checklist", checklistFor(job));

        TextView score = label("Job Fit\n\n" + matchScore(job) + "%\n\nReview your CV, cover letter, and route before submitting.", 22, GREEN, Typeface.BOLD);
        score.setGravity(Gravity.CENTER);
        score.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(score);
        content.addView(score, cardParams());

        String coverLetter = coverLetterDraft(job);
        addDetailsSection("Editable Cover Letter", coverLetter);

        TextView copy = button("Copy Cover Letter", MINT, GREEN);
        copy.setOnClickListener(view -> copyToClipboard("Cover Letter", coverLetter));
        content.addView(copy, matchHeight(dp(56)));

        TextView submit = button("Submit Application", GREEN, Color.WHITE);
        submit.setOnClickListener(view -> routeApplication(job));
        LinearLayout.LayoutParams submitParams = matchHeight(dp(62));
        submitParams.setMargins(0, dp(18), 0, dp(18));
        content.addView(submit, submitParams);
    }

    private String applicationCopy(Job job) {
        if (isGovernmentMethod(job)) {
            if (isEmailMethod(job)) {
                return "Review the Z83 requirement, reference number, CV, and supporting documents. Submit Application then opens your email app with the government application draft.";
            }
            if (isWebsiteMethod(job)) {
                return "Review the Z83 requirement, reference number, CV, and supporting documents. Submit Application then opens the official government application website.";
            }
            return "Review the Z83 requirement, reference number, CV, and supporting document checklist before you submit.";
        }

        if (isEmailMethod(job)) {
            return "Let's Apply prepares your subject line and email draft. Your email app opens so you can review and press Send yourself.";
        }

        if (isWebsiteMethod(job)) {
            return "Let's Apply prepares your documents first, then opens the employer website so you can complete the official form.";
        }

        if ("manualInstruction".equals(job.method)) {
            return "Follow the listed instructions. The app keeps the CV and cover letter ready for export.";
        }

        return "This vacancy can be submitted inside Let's Apply and tracked in your applications.";
    }

    private String checklistFor(Job job) {
        StringBuilder builder = new StringBuilder();
        builder.append("Detailed CV\n");
        builder.append("Tailored cover letter\n");
        if (isGovernmentMethod(job)) {
            builder.append("Completed and signed Z83 form\n");
            builder.append("Reference ").append(referenceValue(job)).append(" confirmed\n");
            builder.append("Certified ID and qualifications if required\n");
        }
        if (isEmailMethod(job)) {
            builder.append("Recruiter email checked\n");
        }
        if (isWebsiteMethod(job)) {
            builder.append("Official portal link checked\n");
        }
        return builder.toString().trim();
    }

    private int matchScore(Job job) {
        String text = (job.title + " " + job.requirements + " " + job.description).toLowerCase(Locale.ROOT);
        int score = 52;
        if (text.contains("research") || text.contains("analysis")) score += 12;
        if (text.contains("report") || text.contains("writing")) score += 10;
        if (text.contains("monitoring") || text.contains("evaluation")) score += 12;
        if (text.contains("customer")) score -= 6;
        if (isGovernmentMethod(job)) score += 7;
        if (score > 94) return 94;
        if (score < 38) return 38;
        return score;
    }

    private String coverLetterDraft(Job job) {
        String greeting = isGovernmentMethod(job) ? "Dear Selection Committee," : "Dear Hiring Manager,";
        return greeting + "\n\n"
                + "APPLICATION FOR THE POSITION OF " + job.title.toUpperCase(Locale.ROOT) + "\n\n"
                + "I am applying for the " + job.title + " position at " + job.company + ". My profile brings together public-sector awareness, structured analysis, stakeholder communication, and digital systems experience, which I would apply carefully to the responsibilities of this role.\n\n"
                + "The vacancy calls for someone who can understand requirements, work with accuracy, communicate clearly, and deliver dependable results. My background in research, monitoring and evaluation, academic administration, and technology-supported process improvement has prepared me to approach that work with evidence, discipline, and practical judgement.\n\n"
                + "I would welcome the opportunity to contribute to " + job.company + " by bringing a professional standard of preparation, clear written communication, and a service-minded approach to the post. Thank you for considering my application.\n\n"
                + "Kind regards";
    }

    private void routeApplication(Job job) {
        if (isEmailMethod(job)) {
            openEmailApplication(job);
            return;
        }

        if (isWebsiteMethod(job)) {
            openApplicationWebsite(job);
            return;
        }

        if ("manualInstruction".equals(job.method) || "governmentManual".equals(job.method)) {
            showManualInstructions(job);
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Application submitted")
                .setMessage("This vacancy has been prepared for in-app submission. Application tracking will sync to Firebase in the next Android phase.")
                .setPositiveButton("OK", null)
                .show();
    }

    private void openEmailApplication(Job job) {
        if (job.applicationEmail == null || job.applicationEmail.trim().isEmpty()) {
            showMissingApplicationContact(job);
            return;
        }

        String subject = "Application: " + job.title + referenceSuffix(job);
        String body = emailDraft(job);

        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:" + Uri.encode(job.applicationEmail.trim())));
        intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        intent.putExtra(Intent.EXTRA_TEXT, body);

        if (intent.resolveActivity(getPackageManager()) == null) {
            showMissingEmailApp(job, subject, body);
            return;
        }

        startActivity(intent);
    }

    private String emailDraft(Job job) {
        return "Dear Hiring Manager,\n\n"
                + "Please receive my application for the " + job.title + " position" + referenceSuffix(job) + ".\n\n"
                + "I have prepared my CV, cover letter, and any required supporting documents for your consideration.\n\n"
                + "Kind regards";
    }

    private void openApplicationWebsite(Job job) {
        if (job.applicationUrl == null || job.applicationUrl.trim().isEmpty()) {
            showMissingApplicationContact(job);
            return;
        }

        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(job.applicationUrl.trim()));
        if (intent.resolveActivity(getPackageManager()) == null) {
            copyToClipboard("Application Link", job.applicationUrl);
            new AlertDialog.Builder(this)
                    .setTitle("Website copied")
                    .setMessage("I could not open a browser, so I copied the application link:\n\n" + job.applicationUrl)
                    .setPositiveButton("OK", null)
                    .show();
            return;
        }

        startActivity(intent);
    }

    private void showManualInstructions(Job job) {
        new AlertDialog.Builder(this)
                .setTitle("Manual application instructions")
                .setMessage("Follow the vacancy instructions for " + job.title + ". Keep your CV, cover letter, Z83, and supporting documents ready before submitting.")
                .setPositiveButton("Copy Reference", (dialog, which) -> copyToClipboard("Reference", referenceValue(job)))
                .setNegativeButton("OK", null)
                .show();
    }

    private void showMissingEmailApp(Job job, String subject, String body) {
        new AlertDialog.Builder(this)
                .setTitle("Email app not available")
                .setMessage("Send your application to:\n\n" + job.applicationEmail + "\n\nSubject:\n" + subject)
                .setPositiveButton("Copy Email", (dialog, which) -> copyToClipboard("Application Email", job.applicationEmail))
                .setNeutralButton("Copy Draft", (dialog, which) -> copyToClipboard("Email Draft", body))
                .setNegativeButton("OK", null)
                .show();
    }

    private void showMissingApplicationContact(Job job) {
        new AlertDialog.Builder(this)
                .setTitle("Application destination missing")
                .setMessage("This vacancy needs an application email or website before Let's Apply can route the submission. The job details are still available for review.")
                .setPositiveButton("Copy Reference", (dialog, which) -> copyToClipboard("Reference", referenceValue(job)))
                .setNegativeButton("OK", null)
                .show();
    }

    private void addContactSection(Job job) {
        StringBuilder builder = new StringBuilder();
        if (job.applicationEmail != null && !job.applicationEmail.trim().isEmpty()) {
            builder.append("Email: ").append(job.applicationEmail.trim()).append("\n");
        }
        if (job.applicationUrl != null && !job.applicationUrl.trim().isEmpty()) {
            builder.append("Link: ").append(job.applicationUrl.trim()).append("\n");
        }
        if (job.referenceNumber != null && !job.referenceNumber.trim().isEmpty()) {
            builder.append("Reference: ").append(job.referenceNumber.trim());
        }

        if (builder.length() > 0) {
            addDetailsSection("Application Contact", builder.toString().trim());
        }
    }

    private void addDetailsSection(String heading, String body) {
        TextView section = label(heading + "\n\n" + body, 18, INK, Typeface.BOLD);
        section.setTextColor(INK);
        section.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(section);
        LinearLayout.LayoutParams params = cardParams();
        params.setMargins(0, 0, 0, dp(14));
        content.addView(section, params);
    }

    private void sectionHeader(String title, String action, Runnable onAction) {
        LinearLayout header = horizontal();
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, dp(8), 0, dp(14));
        content.addView(header, params);

        TextView titleView = label(title, 24, INK, Typeface.BOLD);
        header.addView(titleView, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

        TextView actionView = label(action, 16, GREEN, Typeface.BOLD);
        actionView.setGravity(Gravity.RIGHT);
        actionView.setOnClickListener(view -> onAction.run());
        header.addView(actionView, wrapWrap());
    }

    private void addHorizontalJobScroller(List<Job> jobs, int limit) {
        HorizontalScrollView scroller = new HorizontalScrollView(this);
        scroller.setHorizontalScrollBarEnabled(false);
        LinearLayout row = horizontal();
        scroller.addView(row);
        content.addView(scroller, matchWrap());

        for (int index = 0; index < jobs.size() && index < limit; index++) {
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dp(245), dp(245));
            params.setMargins(0, 0, dp(12), dp(22));
            row.addView(jobCard(jobs.get(index), false), params);
        }
    }

    private void addVerticalJobs(List<Job> jobs, int limit) {
        for (int index = 0; index < jobs.size() && index < limit; index++) {
            content.addView(jobCard(jobs.get(index), false), cardParams());
        }
    }

    private void addCareerTipCard() {
        TextView tip = label(
                "Application Tip\n\nFor government vacancies, check the reference number, closing date, Z83 requirement, and delivery method before you prepare documents.",
                18,
                INK,
                Typeface.BOLD
        );
        tip.setPadding(dp(18), dp(18), dp(18), dp(18));
        tip.setBackground(rounded(Color.WHITE, 18));
        content.addView(tip, cardParams());
    }

    private String sourceLabel(Job job) {
        String source = job.source == null ? "" : job.source.trim();
        if (isGovernmentMethod(job) || source.toLowerCase(Locale.ROOT).contains("dpsa")) {
            return "Public Service";
        }
        if (source.isEmpty()) {
            return "Let's Apply";
        }
        return source;
    }

    private String jobLogoText(Job job) {
        if (job.company == null || job.company.trim().isEmpty()) {
            return "LA";
        }
        String[] words = job.company.trim().split("\\s+");
        if (words.length == 1) {
            return words[0].substring(0, Math.min(2, words[0].length())).toUpperCase(Locale.ROOT);
        }
        return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase(Locale.ROOT);
    }

    private View logoView(Job job, int textSize) {
        if (isGovernmentMethod(job) || sourceLabel(job).equals("Public Service")) {
            ImageView imageView = new ImageView(this);
            imageView.setImageResource(R.drawable.south_africa_coat_of_arms);
            imageView.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
            imageView.setPadding(dp(8), dp(6), dp(8), dp(6));
            imageView.setBackground(rounded(MINT, 12));
            return imageView;
        }

        TextView logo = label(jobLogoText(job), textSize, GREEN, Typeface.BOLD);
        logo.setGravity(Gravity.CENTER);
        logo.setBackground(rounded(MINT, 12));
        return logo;
    }

    private boolean isGovernmentMethod(Job job) {
        return job.method != null && job.method.toLowerCase(Locale.ROOT).startsWith("government");
    }

    private boolean isEmailMethod(Job job) {
        return "email".equals(job.method) || "governmentEmail".equals(job.method);
    }

    private boolean isWebsiteMethod(Job job) {
        return "externalWebsite".equals(job.method)
                || "externalLink".equals(job.method)
                || "governmentWebsite".equals(job.method);
    }

    private String referenceSuffix(Job job) {
        if (job.referenceNumber == null || job.referenceNumber.trim().isEmpty()) {
            return "";
        }
        return " - Ref " + job.referenceNumber.trim();
    }

    private String referenceValue(Job job) {
        return job.referenceNumber == null || job.referenceNumber.trim().isEmpty()
                ? "Reference not listed"
                : job.referenceNumber.trim();
    }

    private void copyToClipboard(String label, String value) {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard != null) {
            clipboard.setPrimaryClip(ClipData.newPlainText(label, value == null ? "" : value));
        }
        new AlertDialog.Builder(this)
                .setTitle("Copied")
                .setMessage(label + " copied.")
                .setPositiveButton("OK", null)
                .show();
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
        button.setElevation(dp(2));
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
        view.setBackground(rounded(Color.WHITE, 16));
        view.setElevation(dp(1));
    }

    private GradientDrawable rounded(int color, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(radius));
        drawable.setStroke(dp(1), BORDER);
        return drawable;
    }

    private GradientDrawable roundedGradient(int startColor, int endColor, int radius) {
        GradientDrawable drawable = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[]{startColor, endColor}
        );
        drawable.setCornerRadius(dp(radius));
        return drawable;
    }
}
