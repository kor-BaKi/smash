package com.smash.api.activity;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import com.smash.scheduler.ActivityScheduler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ActivityServiceTest {

    @Mock ActivityRepository activityRepository;
    @Mock ParticipationRepository participationRepository;
    @Mock UserRepository userRepository;
    @Mock ActivityScheduler activityScheduler;

    @InjectMocks ActivityService activityService;

    private static final Long USER_ID = 1L;
    private static final Long GROUP_ID = 5L;
    private static final Long CURRENT_ID = 100L;
    private static final Long FUTURE_ID = 101L;

    private User user;
    private Activity current;   // 오늘 응답하려는 활동 (10/14)
    private Activity future;    // 이월 대상 후보 (10/21)

    @BeforeEach
    void setUp() {
        user = mock(User.class);
        given(user.getGroupId()).willReturn(GROUP_ID);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        current = activity(CURRENT_ID, LocalDate.of(2026, 10, 14));
        future = activity(FUTURE_ID, LocalDate.of(2026, 10, 21));
        given(activityRepository.findById(CURRENT_ID)).willReturn(Optional.of(current));
        given(activityRepository.findById(FUTURE_ID)).willReturn(Optional.of(future));
        given(activityRepository.findActivitiesByGroupAndMonth(eq(GROUP_ID), any(), any()))
                .willReturn(List.of(current, future));

        given(participationRepository.findByActivityAndUser(current, user))
                .willReturn(Optional.empty());
    }

    // 주의: given(...) 인자 위치에서 호출하지 말고 변수에 먼저 담아 사용할 것
    private Activity activity(Long id, LocalDate date) {
        Activity a = mock(Activity.class);
        given(a.getId()).willReturn(id);
        given(a.getActivityDate()).willReturn(date);
        given(a.isVoteClosed()).willReturn(false);
        return a;
    }

    private ParticipationRequest request(ParticipationType type, Long targetId) {
        ParticipationRequest r = mock(ParticipationRequest.class);
        given(r.getType()).willReturn(type);
        given(r.getTargetActivityId()).willReturn(targetId);
        return r;
    }

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    @Test
    @DisplayName("이월: 선택 가능한 미래 날짜면 이월 참여가 저장된다")
    void carryover_validTarget_saved() {
        ParticipationRequest req = request(ParticipationType.CARRYOVER, FUTURE_ID);

        activityService.participate(USER_ID, CURRENT_ID, req);

        ArgumentCaptor<Participation> captor = ArgumentCaptor.forClass(Participation.class);
        verify(participationRepository).save(captor.capture());
        assertThat(captor.getValue().getType()).isEqualTo(ParticipationType.CARRYOVER);
        assertThat(captor.getValue().getCarryoverTarget()).isSameAs(future);
    }

    @Test
    @DisplayName("이월: 이미 이월 대상으로 사용한 날짜는 INVALID_CARRYOVER_TARGET (중복 방지)")
    void carryover_alreadyUsedTarget_rejected() {
        given(participationRepository.existsByUserAndCarryoverTarget(user, future))
                .willReturn(true);
        ParticipationRequest req = request(ParticipationType.CARRYOVER, FUTURE_ID);

        Throwable thrown = catchThrowable(
                () -> activityService.participate(USER_ID, CURRENT_ID, req));

        assertBusiness(thrown, "INVALID_CARRYOVER_TARGET");
        verify(participationRepository, never()).save(any());
    }

    @Test
    @DisplayName("이월: 이미 정규 참여한 과거 날짜는 대상이 될 수 없다")
    void carryover_pastAttendedTarget_rejected() {
        Activity past = activity(102L, LocalDate.of(2026, 10, 7));
        given(activityRepository.findById(102L)).willReturn(Optional.of(past));
        given(activityRepository.findActivitiesByGroupAndMonth(eq(GROUP_ID), any(), any()))
                .willReturn(List.of(current, past));
        given(participationRepository.existsByUserAndActivityAndType(
                user, past, ParticipationType.REGULAR)).willReturn(true);
        ParticipationRequest req = request(ParticipationType.CARRYOVER, 102L);

        Throwable thrown = catchThrowable(
                () -> activityService.participate(USER_ID, CURRENT_ID, req));

        assertBusiness(thrown, "INVALID_CARRYOVER_TARGET");
        verify(participationRepository, never()).save(any());
    }

    @Test
    @DisplayName("이월: 대상 활동을 보내지 않으면 INVALID_INPUT")
    void carryover_noTarget_rejected() {
        ParticipationRequest req = request(ParticipationType.CARRYOVER, null);

        Throwable thrown = catchThrowable(
                () -> activityService.participate(USER_ID, CURRENT_ID, req));

        assertBusiness(thrown, "INVALID_INPUT");
    }

    @Test
    @DisplayName("투표가 마감된 활동은 VOTE_CLOSED")
    void participate_voteClosed_rejected() {
        given(current.isVoteClosed()).willReturn(true);
        ParticipationRequest req = request(ParticipationType.REGULAR, null);

        Throwable thrown = catchThrowable(
                () -> activityService.participate(USER_ID, CURRENT_ID, req));

        assertBusiness(thrown, "VOTE_CLOSED");
        verify(participationRepository, never()).save(any());
    }
}