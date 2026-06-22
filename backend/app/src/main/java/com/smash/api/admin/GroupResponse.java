package com.smash.api.admin;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;

public record GroupResponse(
        Long id,
        DayOfWeek dayOfWeek,
        TimeSlot timeSlot,
        String label,
        Long leaderUserId,
        long memberCount
) {

    public static GroupResponse of(Group group, long memberCount) {
        return new GroupResponse(
                group.getId(),
                group.getDayOfWeek(),
                group.getTimeSlot(),
                GroupLabel.of(group.getDayOfWeek(), group.getTimeSlot()),
                group.getLeaderUserId(),
                memberCount
        );
    }
}
