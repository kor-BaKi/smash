package com.smash.api.admin;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record ActivitySchedulesRequest(@NotEmpty List<@Valid ScheduleItem> schedules) {

    public record ScheduleItem(
            @NotNull DayOfWeek dayOfWeek,
            @NotNull TimeSlot timeSlot,
            @NotNull Boolean isActive
    ) {
    }
}
