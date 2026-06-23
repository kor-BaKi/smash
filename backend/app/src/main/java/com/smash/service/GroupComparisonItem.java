package com.smash.service;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

public record GroupComparisonItem(
        Long groupId,
        DayOfWeek dayOfWeek,
        TimeSlot timeSlot,
        int guaranteed,
        int fulfilled,
        int shortfallMemberCount,
        double fulfillmentRate
) {
}
