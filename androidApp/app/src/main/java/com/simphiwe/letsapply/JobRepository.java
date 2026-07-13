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
        String normalizedFilter = filter == null ? "All" : filter;
        List<Job> results = new ArrayList<>();

        for (Job job : jobs) {
            boolean matchesQuery = normalizedQuery.isEmpty()
                    || job.title.toLowerCase(Locale.ROOT).contains(normalizedQuery)
                    || job.company.toLowerCase(Locale.ROOT).contains(normalizedQuery)
                    || job.requirements.toLowerCase(Locale.ROOT).contains(normalizedQuery);

            boolean matchesFilter = "All".equals(normalizedFilter)
                    || ("Remote".equals(normalizedFilter) && job.remote)
                    || ("Hybrid".equals(normalizedFilter) && job.type.toLowerCase(Locale.ROOT).contains("hybrid"))
                    || ("Featured".equals(normalizedFilter) && job.featured)
                    || ("Government".equals(normalizedFilter) && job.method.startsWith("government"))
                    || ("Public Service".equals(normalizedFilter) && job.method.startsWith("government"))
                    || ("Permanent".equals(normalizedFilter) && job.type.equalsIgnoreCase("Permanent"))
                    || ("Contract".equals(normalizedFilter) && job.type.equalsIgnoreCase("Contract"));

            if (matchesQuery && matchesFilter) {
                results.add(job);
            }
        }

        return results;
    }
}
