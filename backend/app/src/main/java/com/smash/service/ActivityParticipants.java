package com.smash.service;

import java.util.List;

public record ActivityParticipants(
        List<ParticipantView> regular,
        List<ParticipantView> carryover,
        List<ParticipantView> otherGroup,
        List<ParticipantView> freeAttend,
        List<ParticipantView> absent
) {
}
