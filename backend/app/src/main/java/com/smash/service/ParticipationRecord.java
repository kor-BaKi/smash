package com.smash.service;

import com.smash.domain.participation.ParticipationType;

public record ParticipationRecord(Long activityId, ParticipationType type, Long carryoverTargetActivityId) {
}
