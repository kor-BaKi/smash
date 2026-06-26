package com.smash.api.activity;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class ActivityDetailResponse {

    private Long activityId;
    private LocalDate activityDate;
    private String groupLabel;
    private String activityType;
    private boolean isCancelled;
    private Summary summary;
    private Participants participants;

    @Getter
    @Builder
    public static class Summary {
        private int regular;
        private int carryover;
        private int otherGroup;
        private int freeAttend;
        private int absent;
    }


    @Getter
    @Builder
    public static class Participants {
        private List<UserInfo> regular;
        private List<UserInfo> carryover;
        private List<UserInfo> otherGroup;
        private List<UserInfo> freeAttend;
        private List<UserInfo> absent;
    }

    @Getter
    @Builder
    public static class UserInfo {
        private Long userId;
        private String name;
    }
}
