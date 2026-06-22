package com.smash.service;

import com.smash.domain.activity.ActivityType;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.participation.ParticipationType;
import java.time.LocalDate;
import java.util.List;

public record ActivityTodayView(
        Long activityId,
        LocalDate activityDate,
        Long groupId,
        DayOfWeek groupDayOfWeek,
        TimeSlot groupTimeSlot,
        ActivityType activityType,
        boolean isMyGroup,
        List<ParticipationType> availableButtons,
        ParticipationType myParticipationType,
        Long myParticipationTargetActivityId,
        boolean voteClosed
) {
}
