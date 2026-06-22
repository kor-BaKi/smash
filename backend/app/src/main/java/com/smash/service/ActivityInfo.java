package com.smash.service;

import com.smash.domain.activity.ActivityType;
import java.time.LocalDate;

public record ActivityInfo(Long activityId, LocalDate activityDate, Long groupId, ActivityType activityType, boolean cancelled) {
}
