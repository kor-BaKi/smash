package com.smash.service;

import com.smash.domain.activity.ActivityType;
import com.smash.domain.participation.ParticipationType;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

// 04-핵심로직.md 엔진2 의사코드 그대로. Spring/DB에 의존하지 않는 순수 로직이라
// Service가 미리 읽어온 슬라이스(한 부원의 이번달 참여기록 + 그룹 활동목록)를 그대로 넘겨주면 된다.
public final class CarryoverEngine {

    private CarryoverEngine() {
    }

    // 이 활동에서 자격이 "빠졌는지" - 즉 이 활동을 이월 대상(target)으로 잡은 CARRYOVER 기록이 있는지.
    public static boolean hasCarryoverOut(List<ParticipationRecord> participations, Long activityId) {
        return participations.stream().anyMatch(p ->
                p.type() == ParticipationType.CARRYOVER && activityId.equals(p.carryoverTargetActivityId()));
    }

    // 이 활동에 본인 조 정규 참여(REGULAR) 응답을 했는지.
    public static boolean hasRegularAttend(List<ParticipationRecord> participations, Long activityId) {
        return participations.stream().anyMatch(p ->
                p.type() == ParticipationType.REGULAR && activityId.equals(p.activityId()));
    }

    // D-1: 버튼 분기.
    public static List<ParticipationType> resolveButtons(
            ActivityInfo activity, boolean isMyGroup, List<ParticipationRecord> myParticipations) {
        if (activity.activityType() == ActivityType.FREE) {
            return List.of(ParticipationType.FREE_ATTEND, ParticipationType.ABSENT);
        }
        if (isMyGroup) {
            if (hasCarryoverOut(myParticipations, activity.activityId())) {
                return List.of(ParticipationType.CARRYOVER, ParticipationType.OTHER_GROUP);
            }
            return List.of(ParticipationType.REGULAR, ParticipationType.ABSENT);
        }
        return List.of(ParticipationType.CARRYOVER, ParticipationType.OTHER_GROUP);
    }

    // D-3: 이월 후보. myGroupActivitiesInMonth는 이미 당월 범위로 필터링된 본인 조 활동이어야 한다.
    public static List<CarryoverCandidate> getCarryoverCandidates(
            List<ActivityInfo> myGroupActivitiesInMonth, List<ParticipationRecord> myParticipations, LocalDate today) {
        List<CarryoverCandidate> candidates = new ArrayList<>();
        for (ActivityInfo activity : myGroupActivitiesInMonth) {
            if (hasCarryoverOut(myParticipations, activity.activityId())) {
                continue;
            }
            if (activity.activityDate().isAfter(today)) {
                candidates.add(new CarryoverCandidate(activity.activityId(), activity.activityDate(), CandidateStatus.FUTURE));
            } else if (activity.activityDate().isBefore(today)) {
                if (!hasRegularAttend(myParticipations, activity.activityId())) {
                    candidates.add(new CarryoverCandidate(activity.activityId(), activity.activityDate(), CandidateStatus.PAST_ABSENT));
                }
            }
        }
        return candidates;
    }

    // E-1: 충족 계산에 포함되는 유형(REGULAR/CARRYOVER)인지. OTHER_GROUP/FREE_ATTEND/ABSENT는 제외.
    public static boolean countsTowardFulfillment(ParticipationType type) {
        return type == ParticipationType.REGULAR || type == ParticipationType.CARRYOVER;
    }

    public static Fulfillment calculateFulfillment(int guaranteed, int fulfilled) {
        return new Fulfillment(guaranteed, fulfilled, Math.max(0, guaranteed - fulfilled));
    }
}
