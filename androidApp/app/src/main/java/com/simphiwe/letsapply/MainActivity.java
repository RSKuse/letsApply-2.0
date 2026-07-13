package com.simphiwe.letsapply;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
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

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
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
    private SharedPreferences preferences;

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
        preferences = getSharedPreferences("lets_apply_android", MODE_PRIVATE);
        guestMode = !profileExists();
        firestoreRepository = new FirestoreJobRepository(this);
        fetchJobs();
        if (profileExists()) {
            showMain("Home");
        } else {
            showOnboarding();
        }
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
            if (!profileExists()) {
                showProfileEditor();
            }
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
            showMain("Profile");
            showProfileEditor();
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
        nav.bringToFront();

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
        content.setPadding(dp(horizontalPadding), dp(topPadding), dp(horizontalPadding), dp(bottomPadding + 92));
        scroll.addView(content, matchWrap());
        screenFrame.addView(
                scroll,
                new FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                )
        );
    }

    private void addNavItem(LinearLayout nav, String title, String current) {
        TextView item = label(title, 15, title.equals(current) ? GREEN : INK, Typeface.BOLD);
        item.setGravity(Gravity.CENTER);
        item.setClickable(true);
        item.setFocusable(true);
        item.setPadding(dp(4), 0, dp(4), 0);
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
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(320), 1);
        params.setMargins(left ? 0 : dp(6), 0, left ? dp(6) : 0, 0);
        row.addView(jobCard(job, true), params);
    }

    private void renderProfile() {
        setScrollableContent(22, 30, 34);

        TextView title = label(profileExists() ? "Profile" : "Complete Profile", 28, INK, Typeface.BOLD);
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
                !profileExists()
                        ? "Guest profile\nCreate a profile to save jobs, generate documents, and apply."
                        : getProfile("name", "Candidate") + "\n"
                        + getProfile("jobTitle", "Desired role") + "\n"
                        + getProfile("location", "Location") + "\n"
                        + profileCompletionText(),
                20,
                INK,
                Typeface.BOLD
        );
        LinearLayout.LayoutParams profileTextParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        profileTextParams.setMargins(dp(16), 0, 0, 0);
        header.addView(profile, profileTextParams);

        addProfileStatusCard();

        TextView create = button(profileExists() ? "Edit Profile" : "Create Profile", GREEN, Color.WHITE);
        create.setOnClickListener(view -> {
            guestMode = false;
            showProfileEditor();
        });
        content.addView(create, matchHeight(dp(58)));

        addProfileAction("CV Studio", "Build a clean CV, references, certificates, and job-ready sections.", this::showCVStudio);
        addProfileAction("My Applications", "Track submitted, email, website, and government applications.", this::renderApplications);
        addProfileAction("Saved Jobs", "Keep vacancies ready for later review.", this::renderSavedJobs);
    }

    private void addProfileStatusCard() {
        TextView status = label(
                !profileExists()
                        ? "Profile locked\nCreate your profile once. Let the app reuse it for applications."
                        : profileCompletionText() + "\n" + (isProfileComplete()
                        ? "You can apply now. Android document generation is being upgraded to match iOS."
                        : "Complete your name, email, location, job title, summary, and skills to unlock applications."),
                18,
                !profileExists() || !isProfileComplete() ? ORANGE : DARK_GREEN,
                Typeface.BOLD
        );
        status.setPadding(dp(18), dp(18), dp(18), dp(18));
        status.setBackground(rounded(!profileExists() || !isProfileComplete() ? AMBER : MINT, 16));
        LinearLayout.LayoutParams params = cardParams();
        params.setMargins(0, 0, 0, dp(20));
        content.addView(status, params);
    }

    private void addProfileAction(String title, String subtitle, Runnable action) {
        TextView row = label(title + "\n" + subtitle, 18, INK, Typeface.BOLD);
        row.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(row);
        row.setOnClickListener(view -> action.run());
        content.addView(row, cardParams());
    }

    private void showProfileEditor() {
        currentTab = "Profile";
        setScrollableContent(22, 30, 34);

        TextView back = label("< Profile", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Profile"));
        content.addView(back, matchWrap());

        TextView title = label("Build Your Profile", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        TextView intro = label(
                "Complete this once. Let’s Apply will reuse it for matching, CV drafts, cover letters, and application routing.",
                17,
                MUTED,
                Typeface.BOLD
        );
        intro.setPadding(dp(18), dp(18), dp(18), dp(18));
        intro.setBackground(rounded(MINT, 16));
        content.addView(intro, cardParams());

        EditText name = input("Full name", getProfile("name", ""), 1);
        EditText email = input("Email address", getProfile("email", ""), 1);
        EditText phone = input("Phone number", getProfile("phone", ""), 1);
        EditText location = input("Location", getProfile("location", ""), 1);
        EditText jobTitle = input("Desired job title", getProfile("jobTitle", ""), 1);
        EditText summary = input("Professional summary", getProfile("summary", ""), 5);
        EditText skills = input("Skills and keywords", getProfile("skills", ""), 4);

        content.addView(name, inputParams(1));
        content.addView(email, inputParams(1));
        content.addView(phone, inputParams(1));
        content.addView(location, inputParams(1));
        content.addView(jobTitle, inputParams(1));
        content.addView(summary, inputParams(5));
        content.addView(skills, inputParams(4));

        TextView save = button("Save Profile", GREEN, Color.WHITE);
        save.setOnClickListener(view -> {
            preferences.edit()
                    .putString("profile.name", value(name))
                    .putString("profile.email", value(email))
                    .putString("profile.phone", value(phone))
                    .putString("profile.location", value(location))
                    .putString("profile.jobTitle", value(jobTitle))
                    .putString("profile.summary", value(summary))
                    .putString("profile.skills", value(skills))
                    .putBoolean("profile.exists", true)
                    .apply();
            guestMode = false;
            showMain("Profile");
        });
        LinearLayout.LayoutParams saveParams = matchHeight(dp(58));
        saveParams.setMargins(0, dp(10), 0, dp(18));
        content.addView(save, saveParams);
    }

    private void showCVStudio() {
        if (!profileExists()) {
            showCreateProfilePrompt();
            return;
        }

        setScrollableContent(20, 30, 34);

        TextView back = label("< Profile", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Profile"));
        content.addView(back, matchWrap());

        TextView title = label("CV Studio", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        addDetailsSection("Contact Details", contactDetails());

        addCVStudioSection(
                "Professional Summary",
                getProfile("summary", "Add a focused summary that tells employers who you are and what value you bring."),
                () -> editProfileBlock("Professional Summary", "summary", "Write a clear professional summary.", this::showCVStudio)
        );

        addCVStudioSection(
                "Work Experience",
                getProfile("experience", "Add your roles, responsibilities, and achievements."),
                () -> editProfileBlock("Work Experience", "experience", "Example: Assessment Lead, Regent Business School - managed academic assessment processes and reporting.", this::showCVStudio)
        );

        addCVStudioSection(
                "Education",
                getProfile("education", "Add degrees, diplomas, institutions, and dates."),
                () -> editProfileBlock("Education", "education", "Example: BSc Computer Science, University of Cape Town.", this::showCVStudio)
        );

        addCVStudioSection(
                "Certificates Acquired",
                getProfile("certificates", "Add certificates, short courses, licenses, and professional training."),
                () -> editProfileBlock("Certificates Acquired", "certificates", "Example: AWS Certificate; Project Management Certificate.", this::showCVStudio)
        );

        addCVStudioSection(
                "References",
                getProfile("references", "Add up to three references or write: Available on request."),
                () -> editProfileBlock("References", "references", "Reference 1: Name, role, organisation, email, phone.", this::showCVStudio)
        );

        TextView preview = button("Preview CV", GREEN, Color.WHITE);
        preview.setOnClickListener(view -> showCVPreview());
        LinearLayout.LayoutParams previewParams = matchHeight(dp(60));
        previewParams.setMargins(0, dp(8), 0, dp(16));
        content.addView(preview, previewParams);
    }

    private void addCVStudioSection(String title, String body, Runnable action) {
        LinearLayout card = vertical();
        card.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(card);
        card.setOnClickListener(view -> action.run());

        TextView heading = label(title, 22, INK, Typeface.BOLD);
        card.addView(heading, matchWrap());

        TextView text = label(body == null || body.trim().isEmpty() ? "Tap to add details." : body.trim(), 16, MUTED, Typeface.BOLD);
        text.setMaxLines(4);
        LinearLayout.LayoutParams textParams = matchWrap();
        textParams.setMargins(0, dp(8), 0, dp(12));
        card.addView(text, textParams);

        TextView edit = label("Edit", 15, GREEN, Typeface.BOLD);
        edit.setGravity(Gravity.RIGHT);
        card.addView(edit, matchWrap());

        content.addView(card, cardParams());
    }

    private void editProfileBlock(String title, String key, String hint, Runnable onSaved) {
        EditText field = input(hint, getProfile(key, ""), 6);
        field.setMinLines(6);
        field.setSelection(field.getText() == null ? 0 : field.getText().length());

        new AlertDialog.Builder(this)
                .setTitle(title)
                .setView(field)
                .setPositiveButton("Save", (dialog, which) -> {
                    preferences.edit().putString("profile." + key, value(field)).apply();
                    onSaved.run();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void showCVPreview() {
        setScrollableContent(20, 30, 34);

        TextView back = label("< CV Studio", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showCVStudio());
        content.addView(back, matchWrap());

        TextView title = label("CV Preview", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        addDetailsSection("Candidate CV", cvDraft(null));

        TextView copy = button("Copy CV Text", MINT, GREEN);
        copy.setOnClickListener(view -> copyToClipboard("CV Draft", cvDraft(null)));
        content.addView(copy, matchHeight(dp(56)));
    }

    private String contactDetails() {
        StringBuilder builder = new StringBuilder();
        appendLine(builder, getProfile("name", ""));
        appendLine(builder, getProfile("jobTitle", ""));
        appendLine(builder, getProfile("email", ""));
        appendLine(builder, getProfile("phone", ""));
        appendLine(builder, getProfile("location", ""));
        return builder.length() == 0 ? "Complete your profile contact details." : builder.toString().trim();
    }

    private String cvDraft(Job job) {
        StringBuilder builder = new StringBuilder();
        builder.append(contactDetails());

        appendSection(builder, "Professional Summary", getProfile("summary", ""));
        appendSection(builder, "Core Skills", getProfile("skills", ""));
        appendSection(builder, "Work Experience", getProfile("experience", "Add work experience in CV Studio."));
        appendSection(builder, "Education", getProfile("education", "Add education in CV Studio."));
        appendSection(builder, "Certificates Acquired", getProfile("certificates", "Add certificates in CV Studio."));
        appendSection(builder, "References", getProfile("references", "Available on request."));

        if (job != null) {
            appendSection(
                    builder,
                    "Tailored Focus",
                    "For this " + job.title + " application, emphasise " + roleFocus(job) + "."
            );
        }

        return builder.toString().trim();
    }

    private void appendSection(StringBuilder builder, String heading, String value) {
        String cleaned = value == null ? "" : value.trim();
        if (cleaned.isEmpty()) {
            return;
        }
        builder.append("\n\n").append(heading.toUpperCase(Locale.ROOT)).append("\n").append(cleaned);
    }

    private void appendLine(StringBuilder builder, String value) {
        if (value != null && !value.trim().isEmpty()) {
            builder.append(value.trim()).append("\n");
        }
    }

    private void renderApplications() {
        setScrollableContent(20, 30, 34);

        TextView back = label("< Profile", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Profile"));
        content.addView(back, matchWrap());

        TextView title = label("Applications", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        JSONArray applications = loadArray("applications");
        if (applications.length() == 0) {
            TextView empty = label("No applications yet.\n\nWhen you submit or prepare a vacancy, it will appear here.", 18, MUTED, Typeface.BOLD);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(dp(18), dp(18), dp(18), dp(18));
            applyCardStyle(empty);
            content.addView(empty, cardParams());
            return;
        }

        for (int index = applications.length() - 1; index >= 0; index--) {
            JSONObject item = applications.optJSONObject(index);
            if (item != null) {
                addApplicationCard(item, index);
            }
        }
    }

    private void addApplicationCard(JSONObject item, int index) {
        LinearLayout card = vertical();
        card.setPadding(dp(18), dp(18), dp(18), dp(18));
        applyCardStyle(card);

        TextView heading = label(
                item.optString("title", "Application") + "\n"
                        + item.optString("company", "Company") + "\n"
                        + item.optString("status", "Prepared") + " • " + item.optString("date", ""),
                19,
                INK,
                Typeface.BOLD
        );
        card.addView(heading, matchWrap());

        LinearLayout actions = horizontal();
        actions.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams actionParams = matchWrap();
        actionParams.setMargins(0, dp(14), 0, 0);
        card.addView(actions, actionParams);

        TextView copy = label("Copy details", 15, GREEN, Typeface.BOLD);
        copy.setGravity(Gravity.CENTER);
        copy.setPadding(dp(14), dp(10), dp(14), dp(10));
        copy.setBackground(rounded(MINT, 20));
        copy.setOnClickListener(view -> copyToClipboard("Application", applicationSummary(item)));
        actions.addView(copy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

        TextView share = label("Share docs", 15, GREEN, Typeface.BOLD);
        share.setGravity(Gravity.CENTER);
        share.setPadding(dp(14), dp(10), dp(14), dp(10));
        share.setBackground(rounded(MINT, 20));
        share.setOnClickListener(view -> shareStoredApplication(item));
        LinearLayout.LayoutParams shareParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        shareParams.setMargins(dp(10), 0, 0, 0);
        actions.addView(share, shareParams);

        TextView delete = label("Delete", 15, Color.rgb(210, 54, 54), Typeface.BOLD);
        delete.setGravity(Gravity.CENTER);
        delete.setPadding(dp(14), dp(10), dp(14), dp(10));
        delete.setOnClickListener(view -> confirmDeleteApplication(index));
        LinearLayout.LayoutParams deleteParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        deleteParams.setMargins(dp(10), 0, 0, 0);
        actions.addView(delete, deleteParams);

        content.addView(card, cardParams());
    }

    private void renderSavedJobs() {
        setScrollableContent(20, 30, 34);

        TextView back = label("< Profile", 17, GREEN, Typeface.BOLD);
        back.setOnClickListener(view -> showMain("Profile"));
        content.addView(back, matchWrap());

        TextView title = label("Saved Jobs", 28, INK, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.setMargins(0, dp(12), 0, dp(18));
        content.addView(title, titleParams);

        List<String> savedKeys = loadStringList("savedJobs");
        List<Job> savedJobs = new ArrayList<>();
        for (Job job : repository.allJobs()) {
            if (savedKeys.contains(jobKey(job))) {
                savedJobs.add(job);
            }
        }

        if (savedJobs.isEmpty()) {
            TextView empty = label("No saved jobs yet.\n\nOpen a vacancy and tap Save Job to keep it here.", 18, MUTED, Typeface.BOLD);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(dp(18), dp(18), dp(18), dp(18));
            applyCardStyle(empty);
            content.addView(empty, cardParams());
            return;
        }

        for (Job job : savedJobs) {
            LinearLayout card = vertical();
            card.setPadding(dp(16), dp(16), dp(16), dp(16));
            applyCardStyle(card);
            card.setOnClickListener(view -> showJobDetails(job));
            card.addView(label(job.title + "\n" + job.company + "\n" + SalaryFormatter.format(job.currency, job.salaryMin, job.salaryMax, job.salaryPeriod), 18, INK, Typeface.BOLD), matchWrap());

            TextView remove = label("Remove saved job", 15, Color.rgb(210, 54, 54), Typeface.BOLD);
            remove.setPadding(0, dp(14), 0, 0);
            remove.setOnClickListener(view -> {
                setJobSaved(job, false);
                renderSavedJobs();
            });
            card.addView(remove, matchWrap());
            content.addView(card, cardParams());
        }
    }

    private void showFeatureComingSoon(String title) {
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage("This Android screen is being brought up to iOS parity. The profile, saved jobs, and application tracker are active first.")
                .setPositiveButton("OK", null)
                .show();
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
        back.setGravity(Gravity.CENTER_VERTICAL);
        back.setPadding(dp(16), 0, dp(16), 0);
        back.setBackground(rounded(Color.WHITE, 24));
        back.setOnClickListener(view -> showMain("Jobs"));
        content.addView(back, new LinearLayout.LayoutParams(dp(116), dp(52)));

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

        TextView saveJob = button(isJobSaved(job) ? "Saved Job" : "Save Job", isJobSaved(job) ? MINT : GREEN, isJobSaved(job) ? GREEN : Color.WHITE);
        saveJob.setOnClickListener(view -> {
            if (guestMode || !profileExists()) {
                showCreateProfilePrompt();
                return;
            }
            setJobSaved(job, !isJobSaved(job));
            showJobDetails(job);
        });
        LinearLayout.LayoutParams saveParams = matchHeight(dp(54));
        saveParams.setMargins(0, dp(18), 0, 0);
        hero.addView(saveJob, saveParams);

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
        if (guestMode || !profileExists()) {
            showCreateProfilePrompt();
            return;
        }

        if (!isProfileComplete()) {
            new AlertDialog.Builder(this)
                    .setTitle("Complete your profile")
                    .setMessage("Please complete your name, email, location, desired job title, professional summary, and skills before submitting applications.")
                    .setPositiveButton("Complete Profile", (dialog, which) -> showProfileEditor())
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

        String tailoredCv = cvDraft(job);
        String coverLetter = coverLetterDraft(job);
        String applicationEmail = emailDraft(job);

        addDetailsSection("Tailored CV Draft", tailoredCv);
        addDetailsSection("Editable Cover Letter", coverLetter);
        addDetailsSection("Editable Application Email", applicationEmail);

        LinearLayout documentActions = horizontal();
        LinearLayout.LayoutParams documentActionParams = matchWrap();
        documentActionParams.setMargins(0, 0, 0, dp(12));
        content.addView(documentActions, documentActionParams);

        TextView copy = button("Copy Letter", MINT, GREEN);
        copy.setOnClickListener(view -> copyToClipboard("Cover Letter", coverLetter));
        documentActions.addView(copy, new LinearLayout.LayoutParams(0, dp(56), 1));

        TextView share = button("Share Docs", MINT, GREEN);
        share.setOnClickListener(view -> shareApplicationDocuments(job, tailoredCv, coverLetter, applicationEmail));
        LinearLayout.LayoutParams shareParams = new LinearLayout.LayoutParams(0, dp(56), 1);
        shareParams.setMargins(dp(10), 0, 0, 0);
        documentActions.addView(share, shareParams);

        TextView submit = button("Submit Application", GREEN, Color.WHITE);
        submit.setOnClickListener(view -> routeApplication(job, tailoredCv, coverLetter, applicationEmail));
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
        String profileSummary = cleanSentence(getProfile("summary", ""));
        String skills = skillSummary(getProfile("skills", ""));
        String roleFocus = roleFocus(job);
        String applicantName = getProfile("name", "");
        String employer = employerPhrase(job.company);
        String profileIdentity = professionalIdentitySentence(profileSummary);

        StringBuilder letter = new StringBuilder();
        letter.append(greeting).append("\n\n");
        if (isGovernmentMethod(job)) {
            letter.append("APPLICATION FOR THE POSITION OF ")
                    .append(job.title.toUpperCase(Locale.ROOT))
                    .append(referenceSuffix(job).toUpperCase(Locale.ROOT))
                    .append("\n\n");
        }

        letter.append("I am writing to apply for the ")
                .append(job.title)
                .append(" position at ")
                .append(employer)
                .append(". ")
                .append(profileIdentity)
                .append(" ");

        letter.append("I am interested in this opportunity because the role requires ")
                .append(roleFocus)
                .append(", which are closely aligned with the way I approach professional work.")
                .append("\n\n");

        letter.append("My experience has taught me to interpret requirements carefully, organise complex information into clear outputs, and communicate in a way that supports responsible decision-making. ");
        if (!skills.isEmpty()) {
            letter.append("My profile reflects strengths in ")
                    .append(skills)
                    .append(", and I would apply those strengths directly to the duties described in the advertisement. ");
        }
        letter.append("I have considered the vacancy requirements carefully and would approach the post with the seriousness, accuracy, and accountability expected by ")
                .append(employer)
                .append(".")
                .append("\n\n");

        letter.append("I would welcome the opportunity to contribute to this role and to discuss how my background can support the priorities of the post. Thank you for considering my application.")
                .append("\n\n")
                .append("Kind regards");

        if (!applicantName.isEmpty()) {
            letter.append("\n").append(applicantName);
        }

        return letter.toString();
    }

    private String professionalIdentitySentence(String summary) {
        if (summary == null || summary.trim().isEmpty()) {
            return "My background combines structured analysis, careful administration, stakeholder communication, and digital problem solving.";
        }

        String cleaned = summary.trim();
        String lower = cleaned.toLowerCase(Locale.ROOT);
        if (lower.startsWith("i ") || lower.startsWith("my ")) {
            return cleanSentence(cleaned);
        }

        String identity = lowerFirst(cleaned);
        String identityLower = identity.toLowerCase(Locale.ROOT);
        if (identityLower.startsWith("experienced in ")) {
            return cleanSentence("I have experience in " + identity.substring("experienced in ".length()));
        }
        if (identityLower.startsWith("skilled in ")
                || identityLower.startsWith("proficient in ")
                || identityLower.startsWith("qualified in ")) {
            return cleanSentence("I am " + identity);
        }
        if (identityLower.startsWith("specialising in ") || identityLower.startsWith("specializing in ")) {
            int prefixLength = identityLower.startsWith("specialising in ")
                    ? "specialising in ".length()
                    : "specializing in ".length();
            return cleanSentence("I specialise in " + identity.substring(prefixLength));
        }
        if (identityLower.startsWith("a ") || identityLower.startsWith("an ")) {
            return cleanSentence("I am " + identity);
        }

        return cleanSentence("I am " + articleFor(identity) + " " + identity);
    }

    private String employerPhrase(String company) {
        if (company == null || company.trim().isEmpty()) {
            return "the employer";
        }

        String cleaned = company.trim();
        String lower = cleaned.toLowerCase(Locale.ROOT);
        if (lower.startsWith("the ")) {
            return cleaned;
        }

        if (lower.startsWith("department ")
                || lower.startsWith("office ")
                || lower.startsWith("ministry ")
                || lower.startsWith("presidency")) {
            return "the " + cleaned;
        }

        return cleaned;
    }

    private String lowerFirst(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        return value.substring(0, 1).toLowerCase(Locale.ROOT) + value.substring(1);
    }

    private String articleFor(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "a";
        }

        String word = value.trim().split("\\s+")[0].toLowerCase(Locale.ROOT);
        if (word.startsWith("uni") || word.startsWith("use") || word.startsWith("one")) {
            return "a";
        }

        char first = word.charAt(0);
        return "aeiou".indexOf(first) >= 0 ? "an" : "a";
    }

    private String cleanSentence(String value) {
        if (value == null) {
            return "";
        }

        String cleaned = value
                .replace("•", " ")
                .replace("❖", " ")
                .replace("*", " ")
                .replace("\n", " ")
                .replaceAll("\\s+", " ")
                .trim();

        if (cleaned.length() > 240) {
            int sentenceEnd = cleaned.indexOf(". ");
            if (sentenceEnd > 80 && sentenceEnd < 240) {
                cleaned = cleaned.substring(0, sentenceEnd + 1);
            } else {
                cleaned = cleaned.substring(0, 240).trim();
                int lastSpace = cleaned.lastIndexOf(" ");
                if (lastSpace > 120) {
                    cleaned = cleaned.substring(0, lastSpace).trim();
                }
                cleaned = cleaned + ".";
            }
        }

        if (!cleaned.endsWith(".") && !cleaned.endsWith("!") && !cleaned.endsWith("?")) {
            cleaned = cleaned + ".";
        }

        return cleaned;
    }

    private String skillSummary(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "";
        }

        String[] parts = value
                .replace("•", ",")
                .replace("❖", ",")
                .replace("\n", ",")
                .split(",");
        List<String> clean = new ArrayList<>();
        for (String part : parts) {
            String item = part.replaceAll("\\s+", " ").trim();
            if (!item.isEmpty() && item.length() > 2 && clean.size() < 5) {
                clean.add(item);
            }
        }

        if (clean.isEmpty()) {
            return "";
        }

        if (clean.size() == 1) {
            return clean.get(0);
        }

        StringBuilder builder = new StringBuilder();
        for (int index = 0; index < clean.size(); index++) {
            if (index > 0 && index == clean.size() - 1) {
                builder.append(" and ");
            } else if (index > 0) {
                builder.append(", ");
            }
            builder.append(clean.get(index));
        }
        return builder.toString();
    }

    private String roleFocus(Job job) {
        String text = (job.title + " " + job.description + " " + job.requirements).toLowerCase(Locale.ROOT);
        if (text.contains("monitoring") || text.contains("evaluation") || text.contains("research")) {
            return "evidence-led analysis, careful reporting, and the ability to turn complex information into sound decisions";
        }
        if (text.contains("customer") || text.contains("service") || text.contains("client")) {
            return "reliable client service, accuracy under pressure, and clear communication";
        }
        if (text.contains("finance") || text.contains("risk") || text.contains("audit")) {
            return "risk awareness, disciplined analysis, and responsible handling of information";
        }
        if (isGovernmentMethod(job)) {
            return "public-service accountability, policy awareness, accurate documentation, and respectful stakeholder engagement";
        }
        return "clear communication, organised execution, and the ability to deliver work to a dependable professional standard";
    }

    private void routeApplication(Job job) {
        routeApplication(job, cvDraft(job), coverLetterDraft(job), emailDraft(job));
    }

    private void routeApplication(Job job, String cvText, String coverLetter, String applicationEmail) {
        if (isEmailMethod(job)) {
            trackApplication(job, "Email draft prepared", cvText, coverLetter, applicationEmail);
            openEmailApplication(job, applicationEmail, coverLetter, cvText);
            return;
        }

        if (isWebsiteMethod(job)) {
            trackApplication(job, "Website application prepared", cvText, coverLetter, applicationEmail);
            showWebsiteApplicationHandoff(job, cvText, coverLetter, applicationEmail);
            return;
        }

        if ("manualInstruction".equals(job.method) || "governmentManual".equals(job.method)) {
            trackApplication(job, "Manual action required", cvText, coverLetter, applicationEmail);
            showManualInstructions(job);
            return;
        }

        trackApplication(job, "Submitted inside Let’s Apply", cvText, coverLetter, applicationEmail);
        new AlertDialog.Builder(this)
                .setTitle("Application submitted")
                .setMessage("This vacancy has been recorded in My Applications. Firebase application sync will come in the next Android phase.")
                .setPositiveButton("OK", null)
                .show();
    }

    private void openEmailApplication(Job job) {
        openEmailApplication(job, emailDraft(job), coverLetterDraft(job), cvDraft(job));
    }

    private void openEmailApplication(Job job, String emailBody, String coverLetter, String cvText) {
        if (job.applicationEmail == null || job.applicationEmail.trim().isEmpty()) {
            showMissingApplicationContact(job);
            return;
        }

        String subject = "Application: " + job.title + referenceSuffix(job);
        String body = emailBody
                + "\n\n--- Cover Letter ---\n"
                + coverLetter
                + "\n\n--- CV Draft ---\n"
                + cvText;

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

    private void showWebsiteApplicationHandoff(Job job, String cvText, String coverLetter, String applicationEmail) {
        new AlertDialog.Builder(this)
                .setTitle("Open employer website?")
                .setMessage("Your CV draft, cover letter, and application email are prepared. Share or copy them first if you need to attach them on the employer website.")
                .setPositiveButton("Open Website", (dialog, which) -> openApplicationWebsite(job))
                .setNeutralButton("Share Docs", (dialog, which) -> shareApplicationDocuments(job, cvText, coverLetter, applicationEmail))
                .setNegativeButton("Cancel", null)
                .show();
    }

    private String emailDraft(Job job) {
        String greeting = isGovernmentMethod(job) ? "Dear Selection Committee," : "Dear Hiring Manager,";
        String applicantName = getProfile("name", "");
        StringBuilder draft = new StringBuilder();
        draft.append(greeting)
                .append("\n\n")
                .append("Please receive my application for the ")
                .append(job.title)
                .append(" position")
                .append(referenceSuffix(job))
                .append(". I have prepared my CV, cover letter, and the required supporting documents for your consideration. ")
                .append("I would appreciate the opportunity to be considered for this post.")
                .append("\n\n")
                .append("Kind regards");

        if (!applicantName.isEmpty()) {
            draft.append("\n").append(applicantName);
        }

        return draft.toString();
    }

    private void shareApplicationDocuments(Job job, String cvText, String coverLetter, String applicationEmail) {
        String subject = "Application: " + job.title + referenceSuffix(job);
        String text = "Application package prepared by Let's Apply\n\n"
                + "Job: " + job.title + "\n"
                + "Employer: " + job.company + "\n"
                + "Reference: " + referenceValue(job) + "\n\n"
                + "APPLICATION EMAIL\n"
                + applicationEmail + "\n\n"
                + "COVER LETTER\n"
                + coverLetter + "\n\n"
                + "CV DRAFT\n"
                + cvText;

        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_SUBJECT, subject);
        intent.putExtra(Intent.EXTRA_TEXT, text);
        startActivity(Intent.createChooser(intent, "Share application documents"));
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
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dp(265), dp(300));
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

    private void showCreateProfilePrompt() {
        new AlertDialog.Builder(this)
                .setTitle("Create your profile")
                .setMessage("Create your profile to save jobs, prepare documents, and submit applications.")
                .setPositiveButton("Create Profile", (dialog, which) -> {
                    guestMode = false;
                    showMain("Profile");
                    showProfileEditor();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private boolean profileExists() {
        return preferences != null && preferences.getBoolean("profile.exists", false);
    }

    private boolean isProfileComplete() {
        return profileExists()
                && !getProfile("name", "").isEmpty()
                && !getProfile("email", "").isEmpty()
                && !getProfile("location", "").isEmpty()
                && !getProfile("jobTitle", "").isEmpty()
                && !getProfile("summary", "").isEmpty()
                && !getProfile("skills", "").isEmpty();
    }

    private String profileCompletionText() {
        return isProfileComplete() ? "Profile 100% complete" : "Profile needs a few details";
    }

    private String getProfile(String key, String fallback) {
        if (preferences == null) {
            return fallback;
        }
        String value = preferences.getString("profile." + key, fallback);
        return value == null ? fallback : value.trim();
    }

    private EditText input(String hint, String text, int minLines) {
        EditText field = new EditText(this);
        field.setHint(hint);
        field.setText(text);
        field.setTextSize(18);
        field.setTextColor(INK);
        field.setHintTextColor(Color.rgb(150, 156, 162));
        field.setPadding(dp(16), dp(10), dp(16), dp(10));
        field.setMinLines(minLines);
        field.setGravity(minLines > 1 ? Gravity.TOP : Gravity.CENTER_VERTICAL);
        field.setBackground(rounded(Color.WHITE, 14));
        return field;
    }

    private LinearLayout.LayoutParams inputParams(int minLines) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                minLines > 1 ? dp(70 + (minLines * 26)) : dp(58)
        );
        params.setMargins(0, 0, 0, dp(12));
        return params;
    }

    private String value(EditText field) {
        return field.getText() == null ? "" : field.getText().toString().trim();
    }

    private boolean isJobSaved(Job job) {
        return loadStringList("savedJobs").contains(jobKey(job));
    }

    private void setJobSaved(Job job, boolean saved) {
        List<String> keys = loadStringList("savedJobs");
        String key = jobKey(job);
        if (saved && !keys.contains(key)) {
            keys.add(key);
        }
        if (!saved) {
            keys.remove(key);
        }
        saveStringList("savedJobs", keys);
    }

    private String jobKey(Job job) {
        return (job.title + "|" + job.company).toLowerCase(Locale.ROOT);
    }

    private List<String> loadStringList(String key) {
        List<String> values = new ArrayList<>();
        JSONArray array = loadArray(key);
        for (int index = 0; index < array.length(); index++) {
            String value = array.optString(index, "");
            if (!value.isEmpty()) {
                values.add(value);
            }
        }
        return values;
    }

    private void saveStringList(String key, List<String> values) {
        JSONArray array = new JSONArray();
        for (String value : values) {
            array.put(value);
        }
        preferences.edit().putString(key, array.toString()).apply();
    }

    private JSONArray loadArray(String key) {
        if (preferences == null) {
            return new JSONArray();
        }
        String raw = preferences.getString(key, "[]");
        try {
            return new JSONArray(raw == null ? "[]" : raw);
        } catch (JSONException error) {
            return new JSONArray();
        }
    }

    private void saveArray(String key, JSONArray array) {
        preferences.edit().putString(key, array.toString()).apply();
    }

    private void trackApplication(Job job, String status) {
        trackApplication(job, status, cvDraft(job), coverLetterDraft(job), emailDraft(job));
    }

    private void trackApplication(Job job, String status, String cvText, String coverLetter, String emailDraft) {
        JSONArray applications = loadArray("applications");
        String key = jobKey(job);

        for (int index = 0; index < applications.length(); index++) {
            JSONObject existing = applications.optJSONObject(index);
            if (existing != null && key.equals(existing.optString("jobKey"))) {
                existing.remove("status");
                existing.remove("date");
                try {
                    existing.put("status", status);
                    existing.put("date", today());
                    existing.put("cvDraft", cvText == null ? "" : cvText);
                    existing.put("coverLetter", coverLetter == null ? "" : coverLetter);
                    existing.put("emailDraft", emailDraft == null ? "" : emailDraft);
                    existing.put("matchScore", matchScore(job));
                } catch (JSONException ignored) {
                }
                saveArray("applications", applications);
                return;
            }
        }

        JSONObject item = new JSONObject();
        try {
            item.put("jobKey", key);
            item.put("title", job.title);
            item.put("company", job.company);
            item.put("method", job.method);
            item.put("status", status);
            item.put("date", today());
            item.put("reference", referenceValue(job));
            item.put("email", job.applicationEmail == null ? "" : job.applicationEmail);
            item.put("url", job.applicationUrl == null ? "" : job.applicationUrl);
            item.put("cvDraft", cvText == null ? "" : cvText);
            item.put("coverLetter", coverLetter == null ? "" : coverLetter);
            item.put("emailDraft", emailDraft == null ? "" : emailDraft);
            item.put("matchScore", matchScore(job));
        } catch (JSONException ignored) {
        }
        applications.put(item);
        saveArray("applications", applications);
    }

    private String today() {
        return new SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(new Date());
    }

    private String applicationSummary(JSONObject item) {
        return item.optString("title", "Application") + "\n"
                + item.optString("company", "") + "\n"
                + "Status: " + item.optString("status", "") + "\n"
                + "Date: " + item.optString("date", "") + "\n"
                + "Reference: " + item.optString("reference", "") + "\n"
                + "Email: " + item.optString("email", "") + "\n"
                + "Link: " + item.optString("url", "") + "\n"
                + "Match: " + item.optInt("matchScore", 0) + "%\n\n"
                + "Cover Letter\n" + item.optString("coverLetter", "") + "\n\n"
                + "Application Email\n" + item.optString("emailDraft", "") + "\n\n"
                + "CV Draft\n" + item.optString("cvDraft", "");
    }

    private void shareStoredApplication(JSONObject item) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_SUBJECT, "Application: " + item.optString("title", "Let’s Apply"));
        intent.putExtra(Intent.EXTRA_TEXT, applicationSummary(item));
        startActivity(Intent.createChooser(intent, "Share application"));
    }

    private void confirmDeleteApplication(int index) {
        new AlertDialog.Builder(this)
                .setTitle("Delete application?")
                .setMessage("This removes the application from this Android device.")
                .setPositiveButton("Delete", (dialog, which) -> {
                    JSONArray oldItems = loadArray("applications");
                    JSONArray newItems = new JSONArray();
                    for (int i = 0; i < oldItems.length(); i++) {
                        if (i != index) {
                            Object item = oldItems.opt(i);
                            if (item != null) {
                                newItems.put(item);
                            }
                        }
                    }
                    saveArray("applications", newItems);
                    renderApplications();
                })
                .setNegativeButton("Cancel", null)
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
