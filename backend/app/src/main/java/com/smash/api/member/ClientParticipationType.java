package com.smash.api.member;

// 클라이언트 노출명. DB 저장값(ParticipationType)과 ATTEND ↔ REGULAR만 다르다 (CLAUDE.md 5.9).
public enum ClientParticipationType {
    ATTEND,
    OTHER_GROUP,
    FREE_ATTEND,
    ABSENT,
    CARRYOVER
}
