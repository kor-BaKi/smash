package com.smash.api.poll;

import com.smash.api.fcm.FcmService;
import com.smash.api.fcm.PushData;
import com.smash.common.exception.BusinessException;
import com.smash.domain.poll.Poll;
import com.smash.domain.poll.PollOptionRepository;
import com.smash.domain.poll.PollRepository;
import com.smash.domain.poll.PollVoteRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PollServiceTest {

    @Mock PollRepository pollRepository;
    @Mock PollOptionRepository pollOptionRepository;
    @Mock PollVoteRepository pollVoteRepository;
    @Mock UserRepository userRepository;
    @Mock FcmService fcmService;
    @InjectMocks PollService pollService;

    private static final Long USER_ID = 1L;
    private static final Long POLL_ID = 10L;

    private Poll saved;

    @BeforeEach
    void setUp() {
        User user = mock(User.class);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        // 저장된 투표를 그대로 돌려주고, 상세 조회(getDetail)에서도 찾을 수 있게 한다
        given(pollRepository.save(any(Poll.class))).willAnswer(invocation -> {
            saved = invocation.getArgument(0);
            ReflectionTestUtils.setField(saved, "id", POLL_ID);
            return saved;
        });
        given(pollRepository.findById(POLL_ID)).willAnswer(invocation -> Optional.ofNullable(saved));
    }

    private PollRequest request(LocalDateTime closedAt, boolean sendNotification) {
        PollRequest r = mock(PollRequest.class);
        given(r.getTitle()).willReturn("MT 날짜 정하기");
        given(r.getOptions()).willReturn(List.of("토요일", "일요일"));
        given(r.getClosedAt()).willReturn(closedAt);
        given(r.isSendNotification()).willReturn(sendNotification);
        return r;
    }

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    @Test
    @DisplayName("과거 마감 시각이면 INVALID_CLOSE_TIME, 읽을 수 있는 문구이고 아무것도 저장하지 않는다")
    void create_pastClosedAt_rejected() {
        PollRequest req = request(LocalDateTime.now().minusHours(1), false);

        Throwable thrown = catchThrowable(() -> pollService.create(USER_ID, req));

        assertBusiness(thrown, "INVALID_CLOSE_TIME");
        assertThat(thrown).hasMessage("마감 시각은 지금보다 이후로 설정해 주세요.");
        verify(pollRepository, never()).save(any());
        verify(pollOptionRepository, never()).save(any());
    }

    @Test
    @DisplayName("방금 지난 시각(1초 전)도 거절한다")
    void create_justPassedClosedAt_rejected() {
        PollRequest req = request(LocalDateTime.now().minusSeconds(1), false);

        assertBusiness(catchThrowable(() -> pollService.create(USER_ID, req)), "INVALID_CLOSE_TIME");
        verify(pollRepository, never()).save(any());
    }

    @Test
    @DisplayName("거절된 요청은 알림을 보내지 않는다")
    void create_pastClosedAt_noNotification() {
        PollRequest req = request(LocalDateTime.now().minusDays(1), true);

        assertBusiness(catchThrowable(() -> pollService.create(USER_ID, req)), "INVALID_CLOSE_TIME");
        verify(fcmService, never()).sendPollNotification(anyString(), anyString(), anyMap());
    }

    @Test
    @DisplayName("미래 마감 시각이면 저장되고 마감 시각이 그대로 응답된다")
    void create_futureClosedAt_saved() {
        LocalDateTime closedAt = LocalDateTime.now().plusDays(1);
        PollRequest req = request(closedAt, false);

        PollResponse res = pollService.create(USER_ID, req);

        verify(pollRepository).save(any(Poll.class));
        assertThat(res.getClosedAt()).isEqualTo(closedAt);
        assertThat(res.isExpired()).isFalse();
    }

    @Test
    @DisplayName("마감 시각이 없으면(수동 종료) 검증 없이 저장된다")
    void create_nullClosedAt_savedAsManualClose() {
        PollRequest req = request(null, false);

        PollResponse res = pollService.create(USER_ID, req);

        verify(pollRepository).save(any(Poll.class));
        assertThat(res.getClosedAt()).isNull();
        assertThat(res.isExpired()).isFalse();
    }

    @Test
    @DisplayName("미래 마감 시각 + 알림 옵션이면 기존처럼 알림을 보낸다")
    void create_futureClosedAt_sendsNotification() {
        PollRequest req = request(LocalDateTime.now().plusHours(3), true);

        pollService.create(USER_ID, req);

        // 제목과 본문은 그대로, data에는 투표 id가 문자열로 담긴다
        verify(fcmService).sendPollNotification(
                eq("새 투표가 등록되었습니다!"), eq("MT 날짜 정하기"), eq(PushData.poll(POLL_ID)));
    }
}
