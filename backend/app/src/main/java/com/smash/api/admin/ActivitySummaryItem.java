package com.smash.api.admin;

import com.smash.api.activity.ParticipationSummaryItem;
import com.smash.domain.activity.ActivityType;
import com.smash.service.ActivitySummaryView;

public record ActivitySummaryItem(
        Long activityId,
        String groupLabel,
        ActivityType activityType,
        boolean isCancelled,
        ParticipationSummaryItem summary
) {

    public static ActivitySummaryItem from(ActivitySummaryView view) {
        return new ActivitySummaryItem(
                view.activityId(),
                GroupLabel.of(view.groupDayOfWeek(), view.groupTimeSlot()),
                view.activityType(),
                view.cancelled(),
                ParticipationSummaryItem.from(view.summary())
        );
    }
}
