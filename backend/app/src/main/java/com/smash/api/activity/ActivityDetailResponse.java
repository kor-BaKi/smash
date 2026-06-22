package com.smash.api.activity;

import com.smash.api.admin.GroupLabel;
import com.smash.domain.activity.ActivityType;
import com.smash.service.ActivityDetail;
import java.time.LocalDate;

public record ActivityDetailResponse(
        Long activityId,
        LocalDate activityDate,
        String groupLabel,
        ActivityType activityType,
        boolean isCancelled,
        ParticipationSummaryItem summary,
        ActivityParticipantsItem participants
) {

    public static ActivityDetailResponse from(ActivityDetail detail) {
        return new ActivityDetailResponse(
                detail.activityId(),
                detail.activityDate(),
                GroupLabel.of(detail.groupDayOfWeek(), detail.groupTimeSlot()),
                detail.activityType(),
                detail.cancelled(),
                ParticipationSummaryItem.from(detail.summary()),
                ActivityParticipantsItem.from(detail.participants())
        );
    }
}
