package com.smash.api.attendent;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class OtherGroupResponse {

    private Long userId;
    private String name;
    private int count;
    private List<ActivityInfo> activities;

    @Getter
    @Builder
    public static class ActivityInfo {
        private Long activityId;
        private LocalDate date;
        private String groupLabel;
    }
}
