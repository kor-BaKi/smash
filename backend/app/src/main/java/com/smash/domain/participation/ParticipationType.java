package com.smash.domain.participation;

// DB 저장값. 클라이언트 노출명(ATTEND)과는 다르다 — REGULAR ↔ ATTEND 매핑은
// DTO 레이어(api)에서만 처리한다 (CLAUDE.md 5.9).
public enum ParticipationType {
    REGULAR,
    CARRYOVER,
    OTHER_GROUP,
    FREE_ATTEND,
    ABSENT
}
