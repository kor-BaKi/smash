package com.smash.api.activity;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ActivitySummaryResponse {

    private Long activityId;
    private LocalDate activityDate;
    private String groupLabel;
    private String activityType;
    private boolean isCancelled;
    private ActivityDetailResponse.Summary summary;
}
