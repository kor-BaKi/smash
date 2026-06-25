package com.smash.api.schedule;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import lombok.Builder;

@Builder
public class ScheduleResponse {

    private Long id;
    private DayOfWeek dayOfWeek;
    private TimeSlot timeSlot;
    private boolean isActive;

    public Long getId() { return id; }
    public DayOfWeek getDayOfWeek() { return dayOfWeek; }
    public TimeSlot getTimeSlot() { return timeSlot; }

    @JsonProperty("isActive")
    public boolean isActive() { return isActive; }

    public static ScheduleResponse of(ActivitySchedule schedule) {
        return ScheduleResponse.builder()
                .id(schedule.getId())
                .dayOfWeek(schedule.getDayOfWeek())
                .timeSlot(schedule.getTimeSlot())
                .isActive(schedule.isActive())
                .build();
    }
}
