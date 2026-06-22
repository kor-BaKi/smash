package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

public record ActivityScheduleSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot, boolean active) {
}
