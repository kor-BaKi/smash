package com.smash.service;

import com.smash.domain.activity.ActivityType;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import java.time.LocalDate;

public record ActivityDetail(
        Long activityId,
        LocalDate activityDate,
        Long groupId,
        DayOfWeek groupDayOfWeek,
        TimeSlot groupTimeSlot,
        ActivityType activityType,
        boolean cancelled,
        ParticipationSummary summary,
        ActivityParticipants participants
) {
}
