package com.smash.service;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import java.util.List;

public record GroupAttendance(
        Long groupId,
        DayOfWeek dayOfWeek,
        TimeSlot timeSlot,
        int year,
        int month,
        int guaranteedCount,
        List<MemberAttendance> members
) {
}
