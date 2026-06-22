package com.smash.api.admin;

import com.smash.service.MemberAttendance;

public record AttendanceMemberItem(Long userId, String name, int fulfilled, int guaranteed, int shortfall, boolean isShortfall) {

    public static AttendanceMemberItem from(MemberAttendance attendance) {
        return new AttendanceMemberItem(
                attendance.userId(), attendance.name(), attendance.fulfilled(),
                attendance.guaranteed(), attendance.shortfall(), attendance.shortfallExists());
    }
}
