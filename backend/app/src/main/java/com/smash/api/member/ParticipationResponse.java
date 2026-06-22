package com.smash.api.member;

import com.smash.service.ParticipationResult;

public record ParticipationResponse(Long participationId, ClientParticipationType type, Long targetActivityId) {

    public static ParticipationResponse from(ParticipationResult result) {
        return new ParticipationResponse(
                result.participationId(), ParticipationTypeMapper.toClient(result.type()), result.targetActivityId());
    }
}
