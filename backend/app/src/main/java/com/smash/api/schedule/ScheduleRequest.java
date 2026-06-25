package com.smash.api.schedule;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.List;

@Getter
public class ScheduleRequest {

    @NotNull
    private List<ScheduleItem> schedules;

    @Getter
    public static class ScheduleItem {
        @NotNull
        private DayOfWeek dayOfWeek;

        @NotNull
        private TimeSlot timeSlot;

        @NotNull
        private Boolean isActive;
    }

}
