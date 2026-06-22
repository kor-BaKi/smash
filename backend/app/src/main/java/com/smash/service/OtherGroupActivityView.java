package com.smash.service;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import java.time.LocalDate;

public record OtherGroupActivityView(Long activityId, LocalDate date, DayOfWeek groupDayOfWeek, TimeSlot groupTimeSlot) {
}
