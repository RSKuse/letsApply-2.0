package com.simphiwe.letsapply;

import java.util.List;

interface JobLoadCallback {
    void onJobsLoaded(List<Job> jobs);
    void onFallbackRequired(String reason);
}
