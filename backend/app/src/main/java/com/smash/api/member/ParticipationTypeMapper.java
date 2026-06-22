package com.smash.api.member;

import com.smash.domain.participation.ParticipationType;

final class ParticipationTypeMapper {

    private ParticipationTypeMapper() {
    }

    static ParticipationType toDomain(ClientParticipationType type) {
        return switch (type) {
            case ATTEND -> ParticipationType.REGULAR;
            case OTHER_GROUP -> ParticipationType.OTHER_GROUP;
            case FREE_ATTEND -> ParticipationType.FREE_ATTEND;
            case ABSENT -> ParticipationType.ABSENT;
            case CARRYOVER -> ParticipationType.CARRYOVER;
        };
    }

    static ClientParticipationType toClient(ParticipationType type) {
        return switch (type) {
            case REGULAR -> ClientParticipationType.ATTEND;
            case OTHER_GROUP -> ClientParticipationType.OTHER_GROUP;
            case FREE_ATTEND -> ClientParticipationType.FREE_ATTEND;
            case ABSENT -> ClientParticipationType.ABSENT;
            case CARRYOVER -> ClientParticipationType.CARRYOVER;
        };
    }
}
