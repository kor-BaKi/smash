package com.smash.service;

import com.smash.domain.participation.ParticipationType;

public record ParticipationResult(Long participationId, ParticipationType type, Long targetActivityId) {
}
