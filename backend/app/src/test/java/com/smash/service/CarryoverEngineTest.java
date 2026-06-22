package com.smash.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.smash.domain.activity.ActivityType;
import com.smash.domain.participation.ParticipationType;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class CarryoverEngineTest {

    private static final Long ACTIVITY_ID = 100L;
    private static final LocalDate TODAY = LocalDate.of(2026, 6, 12);

    @Test
    void TC1_본인조_정규참여REGULAR는_충족계산에_포함된다() {
        assertThat(CarryoverEngine.countsTowardFulfillment(ParticipationType.REGULAR)).isTrue();

        Fulfillment fulfillment = CarryoverEngine.calculateFulfillment(4, 1);

        assertThat(fulfillment.fulfilled()).isEqualTo(1);
        assertThat(fulfillment.shortfall()).isEqualTo(3);
    }

    @Test
    void TC2_사전이월로_자격이_빠진_날의_버튼은_CARRYOVER_OTHER_GROUP이고_CARRYOVER도_충족에_포함된다() {
        ActivityInfo myGroupActivity = new ActivityInfo(ACTIVITY_ID, TODAY, 1L, ActivityType.REGULAR, false);
        List<ParticipationRecord> myParticipations = List.of(
                new ParticipationRecord(200L, ParticipationType.CARRYOVER, ACTIVITY_ID));

        List<ParticipationType> buttons = CarryoverEngine.resolveButtons(myGroupActivity, true, myParticipations);

        assertThat(buttons).containsExactly(ParticipationType.CARRYOVER, ParticipationType.OTHER_GROUP);
        assertThat(CarryoverEngine.countsTowardFulfillment(ParticipationType.CARRYOVER)).isTrue();
    }

    @Test
    void TC3_과거미참여일은_PAST_ABSENT_후보로_뜬다() {
        ActivityInfo pastActivity = new ActivityInfo(1L, TODAY.minusDays(3), 1L, ActivityType.REGULAR, false);

        List<CarryoverCandidate> candidates = CarryoverEngine.getCarryoverCandidates(
                List.of(pastActivity), List.of(), TODAY);

        assertThat(candidates).containsExactly(new CarryoverCandidate(1L, TODAY.minusDays(3), CandidateStatus.PAST_ABSENT));
    }

    @Test
    void TC4_이미_참여한_과거일은_후보에서_제외된다() {
        ActivityInfo pastActivity = new ActivityInfo(1L, TODAY.minusDays(3), 1L, ActivityType.REGULAR, false);
        List<ParticipationRecord> myParticipations = List.of(
                new ParticipationRecord(1L, ParticipationType.REGULAR, null));

        List<CarryoverCandidate> candidates = CarryoverEngine.getCarryoverCandidates(
                List.of(pastActivity), myParticipations, TODAY);

        assertThat(candidates).isEmpty();
    }

    @Test
    void TC5_타조참OTHER_GROUP은_충족계산에서_제외된다() {
        assertThat(CarryoverEngine.countsTowardFulfillment(ParticipationType.OTHER_GROUP)).isFalse();
        assertThat(CarryoverEngine.countsTowardFulfillment(ParticipationType.FREE_ATTEND)).isFalse();
        assertThat(CarryoverEngine.countsTowardFulfillment(ParticipationType.ABSENT)).isFalse();
    }

    @Test
    void TC6_이월취소로_기록이_삭제되면_버튼은_REGULAR_ABSENT로_복구된다() {
        ActivityInfo myGroupActivity = new ActivityInfo(ACTIVITY_ID, TODAY, 1L, ActivityType.REGULAR, false);

        List<ParticipationType> buttons = CarryoverEngine.resolveButtons(myGroupActivity, true, List.of());

        assertThat(buttons).containsExactly(ParticipationType.REGULAR, ParticipationType.ABSENT);
    }

    @Test
    void TC7_당월범위로_미리_걸러진_목록만_넘기면_범위밖_활동은_후보에_없다() {
        // 당월 경계 필터링은 Service의 레포지토리 쿼리(findByGroupIdAndActivityDateBetween) 책임.
        // 엔진은 넘겨받은 목록만 본다 - 다음달 활동은 처음부터 입력에 없어야 한다.
        ActivityInfo thisMonth = new ActivityInfo(1L, TODAY.minusDays(1), 1L, ActivityType.REGULAR, false);

        List<CarryoverCandidate> candidates = CarryoverEngine.getCarryoverCandidates(
                List.of(thisMonth), List.of(), TODAY);

        assertThat(candidates).extracting(CarryoverCandidate::activityId).containsExactly(1L);
    }

    @Test
    void TC8_보낼_자격을_모두_써버렸으면_후보가_없다() {
        ActivityInfo pastAttended = new ActivityInfo(1L, TODAY.minusDays(2), 1L, ActivityType.REGULAR, false);
        ActivityInfo alreadyCarriedOut = new ActivityInfo(2L, TODAY.plusDays(2), 1L, ActivityType.REGULAR, false);
        List<ParticipationRecord> myParticipations = List.of(
                new ParticipationRecord(1L, ParticipationType.REGULAR, null),
                new ParticipationRecord(3L, ParticipationType.CARRYOVER, 2L));

        List<CarryoverCandidate> candidates = CarryoverEngine.getCarryoverCandidates(
                List.of(pastAttended, alreadyCarriedOut), myParticipations, TODAY);

        assertThat(candidates).isEmpty();
    }
}
