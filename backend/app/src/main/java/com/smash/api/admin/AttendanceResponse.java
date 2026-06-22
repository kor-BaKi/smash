package com.smash.api.admin;

import com.smash.service.GroupAttendance;
import java.util.List;

public record AttendanceResponse(
        Long groupId,
        String groupLabel,
        int year,
        int month,
        int guaranteedCount,
        List<AttendanceMemberItem> members
) {

    public static AttendanceResponse from(GroupAttendance attendance) {
        return new AttendanceResponse(
                attendance.groupId(),
                GroupLabel.of(attendance.dayOfWeek(), attendance.timeSlot()),
                attendance.year(),
                attendance.month(),
                attendance.guaranteedCount(),
                attendance.members().stream().map(AttendanceMemberItem::from).toList()
        );
    }
}
