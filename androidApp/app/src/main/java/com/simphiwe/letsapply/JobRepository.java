package com.simphiwe.letsapply;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

final class JobRepository {
    private final List<Job> jobs = new ArrayList<>();

    JobRepository() {
        jobs.add(new Job(
                "Senior Agricultural Scientist",
                "Department of Agriculture",
                "Eastern Cape, South Africa",
                "Permanent",
                "governmentEmail",
                "DPSA Circular",
                "applications@agriculture.gov.za",
                "https://www.dpsa.gov.za/newsroom/psvc",
                "AGR/SCI/2026",
                "Support research, extension, and public service delivery in agricultural development.",
                "Degree or diploma, public service knowledge, report writing, and relevant field experience.",
                "ZAR",
                487197,
                0,
                "per annum",
                false,
                true
        ));
        jobs.add(new Job(
                "Branch Service Official",
                "Absa Bank Limited",
                "Durban, South Africa",
                "Full-time",
                "externalWebsite",
                "Company careers",
                "",
                "https://www.absa.co.za/about-us/careers/",
                "ABSA-BSO",
                "Serve clients at first point of contact and support accurate branch transactions.",
                "Customer service, data accuracy, communication, and Grade 12.",
                "ZAR",
                18000,
                25000,
                "per month",
                false,
                false
        ));
        jobs.add(new Job(
                "Monitoring and Evaluation Officer",
                "International Development Partner",
                "Remote",
                "Contract",
                "email",
                "Partner feed",
                "recruitment@example.org",
                "",
                "MEO-REMOTE",
                "Track programme outcomes, synthesize evidence, and prepare donor-ready reports.",
                "M&E experience, analysis, stakeholder reporting, and strong writing.",
                "USD",
                35,
                50,
                "per hour",
                true,
                true
        ));
    }

    List<Job> allJobs() {
        return new ArrayList<>(jobs);
    }

    void replaceJobs(List<Job> remoteJobs) {
        if (remoteJobs == null || remoteJobs.isEmpty()) {
            return;
        }

        jobs.clear();
        jobs.addAll(remoteJobs);
    }

    List<Job> filter(String query, String filter) {
        String normalizedQuery = query == null ? "" : query.toLowerCase(Locale.ROOT).trim();
        String normalizedFilter = filter == null || filter.trim().isEmpty() ? "All" : filter.trim();
        String lowerFilter = normalizedFilter.toLowerCase(Locale.ROOT);
        List<Job> results = new ArrayList<>();

        for (Job job : jobs) {
            boolean matchesQuery = normalizedQuery.isEmpty()
                    || job.title.toLowerCase(Locale.ROOT).contains(normalizedQuery)
                    || job.company.toLowerCase(Locale.ROOT).contains(normalizedQuery)
                    || job.requirements.toLowerCase(Locale.ROOT).contains(normalizedQuery);

            boolean matchesKnownFilter = "all".equals(lowerFilter)
                    || ("remote".equals(lowerFilter) && job.remote)
                    || ("hybrid".equals(lowerFilter) && job.type.toLowerCase(Locale.ROOT).contains("hybrid"))
                    || ("featured".equals(lowerFilter) && job.featured)
                    || ("government".equals(lowerFilter) && job.method.startsWith("government"))
                    || ("public service".equals(lowerFilter) && job.method.startsWith("government"))
                    || ("permanent".equals(lowerFilter) && job.type.equalsIgnoreCase("Permanent"))
                    || ("contract".equals(lowerFilter) && job.type.equalsIgnoreCase("Contract"));

            boolean customFilter = !isKnownFilter(lowerFilter)
                    && (job.company.toLowerCase(Locale.ROOT).contains(lowerFilter)
                    || job.source.toLowerCase(Locale.ROOT).contains(lowerFilter)
                    || job.location.toLowerCase(Locale.ROOT).contains(lowerFilter)
                    || job.type.toLowerCase(Locale.ROOT).contains(lowerFilter));

            if (matchesQuery && (matchesKnownFilter || customFilter)) {
                results.add(job);
            }
        }

        return results;
    }

    private boolean isKnownFilter(String filter) {
        return "all".equals(filter)
                || "remote".equals(filter)
                || "hybrid".equals(filter)
                || "featured".equals(filter)
                || "government".equals(filter)
                || "public service".equals(filter)
                || "permanent".equals(filter)
                || "contract".equals(filter);
    }
}
