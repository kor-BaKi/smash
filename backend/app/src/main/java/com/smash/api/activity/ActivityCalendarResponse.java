package com.smash.api.activity;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.api.schedule.FreePeriodResponse;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

// 월별 활동 캘린더 (부원용): 내 조 활동일 + 자유 활동 기간
@Getter
@Builder
public class ActivityCalendarResponse {

    private int year;
    private int month;
    private MyGroup myGroup; // 조 미배정이면 null
    private List<Day> activities;
    private List<FreePeriodResponse> freePeriods;

    @Getter
    @Builder
    public static class MyGroup {
        private Long groupId;
        private String label;
    }

    @Getter
    @Builder
    public static class Day {
        private LocalDate date;
        private Long activityId;     // 예측일이면 null
        private String activityType; // REGULAR / FREE
        private boolean isCancelled;
        private boolean isProjected; // true: 아직 생성되지 않은 미래 활동을 규칙으로 계산한 값

        @JsonProperty("isCancelled")
        public boolean isCancelled() { return isCancelled; }

        @JsonProperty("isProjected")
        public boolean isProjected() { return isProjected; }
    }
}
