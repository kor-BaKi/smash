package com.smash.service;

public record MemberAttendance(Long userId, String name, int fulfilled, int guaranteed, int shortfall, boolean shortfallExists) {
}
