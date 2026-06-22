package com.smash.service;

import com.smash.domain.activity.ActivityType;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

public record ActivitySummaryView(
        Long activityId,
        Long groupId,
        DayOfWeek groupDayOfWeek,
        TimeSlot groupTimeSlot,
        ActivityType activityType,
        boolean cancelled,
        ParticipationSummary summary
) {
}
