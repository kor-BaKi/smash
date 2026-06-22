package com.smash.service;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

public record ShortfallMember(
        Long userId,
        String name,
        Long groupId,
        DayOfWeek groupDayOfWeek,
        TimeSlot groupTimeSlot,
        int fulfilled,
        int guaranteed,
        int shortfall
) {
}
