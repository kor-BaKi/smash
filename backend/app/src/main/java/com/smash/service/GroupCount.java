package com.smash.service;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

// label 문자열은 presentation 관심사라 api 레이어에서 만든다. 여기서는 재료(day/time)만 전달.
public record GroupCount(Long groupId, DayOfWeek dayOfWeek, TimeSlot timeSlot, int count) {
}
