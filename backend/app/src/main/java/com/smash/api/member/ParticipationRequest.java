package com.smash.api.member;

import jakarta.validation.constraints.NotNull;

public record ParticipationRequest(@NotNull ClientParticipationType type, Long targetActivityId) {
}
