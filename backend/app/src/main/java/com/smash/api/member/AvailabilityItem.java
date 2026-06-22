package com.smash.api.member;

import com.smash.api.admin.GroupLabel;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;

public record AvailabilityItem(Long groupId, DayOfWeek dayOfWeek, TimeSlot timeSlot, String label) {

    public static AvailabilityItem from(Group group) {
        return new AvailabilityItem(
                group.getId(), group.getDayOfWeek(), group.getTimeSlot(),
                GroupLabel.of(group.getDayOfWeek(), group.getTimeSlot()));
    }
}
