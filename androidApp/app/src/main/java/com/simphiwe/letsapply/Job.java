package com.simphiwe.letsapply;

final class Job {
    final String title;
    final String company;
    final String location;
    final String type;
    final String method;
    final String source;
    final String applicationEmail;
    final String applicationUrl;
    final String referenceNumber;
    final String description;
    final String requirements;
    final String currency;
    final int salaryMin;
    final int salaryMax;
    final String salaryPeriod;
    final boolean remote;
    final boolean featured;

    Job(
            String title,
            String company,
            String location,
            String type,
            String method,
            String source,
            String applicationEmail,
            String applicationUrl,
            String referenceNumber,
            String description,
            String requirements,
            String currency,
            int salaryMin,
            int salaryMax,
            String salaryPeriod,
            boolean remote,
            boolean featured
    ) {
        this.title = title;
        this.company = company;
        this.location = location;
        this.type = type;
        this.method = method;
        this.source = source;
        this.applicationEmail = applicationEmail;
        this.applicationUrl = applicationUrl;
        this.referenceNumber = referenceNumber;
        this.description = description;
        this.requirements = requirements;
        this.currency = currency;
        this.salaryMin = salaryMin;
        this.salaryMax = salaryMax;
        this.salaryPeriod = salaryPeriod;
        this.remote = remote;
        this.featured = featured;
    }
}
