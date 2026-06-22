package com.smash.api.admin;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;

public record GroupCreatedResponse(Long id, DayOfWeek dayOfWeek, TimeSlot timeSlot, String label) {

    public static GroupCreatedResponse from(Group group) {
        return new GroupCreatedResponse(
                group.getId(),
                group.getDayOfWeek(),
                group.getTimeSlot(),
                GroupLabel.of(group.getDayOfWeek(), group.getTimeSlot())
        );
    }
}
