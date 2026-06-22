package com.smash.api.admin;

import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

public record ActivityScheduleResponse(Long id, DayOfWeek dayOfWeek, TimeSlot timeSlot, boolean isActive) {

    public static ActivityScheduleResponse from(ActivitySchedule schedule) {
        return new ActivityScheduleResponse(
                schedule.getId(), schedule.getDayOfWeek(), schedule.getTimeSlot(), schedule.isActive());
    }
}
