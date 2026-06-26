package com.smash.api.activity;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.activity.ActivityType;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Builder
public class ActivityResponse {

    private Long activityId;
    private LocalDate activityDate;
    private Long groupId;
    private String groupLabel;
    private ActivityType activityType;
    private boolean isMyGroup;
    private List<String> availableButtons; // 서버가 결정해서 내려주는 버튼 목록 (["ATTEND", "ABSENT"] 형태)
    private ParticipationInfo myParticipation;
    private boolean voteClosed; // 투표 마감 여부

    public Long getActivityId() { return activityId; }
    public LocalDate getActivityDate() { return activityDate; }
    public Long getGroupId() { return groupId; }
    public String getGroupLabel() { return groupLabel; }
    public ActivityType getActivityType() { return activityType; }
    public List<String> getAvailableButtons() { return availableButtons; }
    public ParticipationInfo getMyParticipation() { return myParticipation; }
    public boolean isVoteClosed() { return voteClosed; }

    @JsonProperty("isMyGroup")
    public boolean isMyGroup() { return isMyGroup; }

    @Getter
    @Builder
    public static class ParticipationInfo {
        private Long participationId;
        private String type;
        private Long targetActivityId;
    }

}
