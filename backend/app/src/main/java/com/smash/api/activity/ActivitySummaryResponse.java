package com.smash.api.activity;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;

import java.time.LocalDate;

@Builder
public class ActivitySummaryResponse {

    private Long activityId;
    private LocalDate activityDate;
    private String groupLabel;
    private String activityType;
    private boolean isCancelled;
    private ActivityDetailResponse.Summary summary;

    public Long getActivityId() { return activityId; }
    public LocalDate getActivityDate() { return activityDate; }
    public String getGroupLabel() { return groupLabel; }
    public String getActivityType() { return activityType; }

    @JsonProperty("isCancelled")
    public boolean isCancelled() { return isCancelled; }

    public ActivityDetailResponse.Summary getSummary() { return summary; }
}