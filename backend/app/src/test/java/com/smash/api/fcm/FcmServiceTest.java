package com.smash.api.fcm;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.smash.domain.user.FcmToken;
import com.smash.domain.user.FcmTokenRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserNotificationSetting;
import com.smash.domain.user.UserNotificationSettingRepository;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class FcmServiceTest {

    @Mock FcmTokenRepository fcmTokenRepository;
    @Mock UserRepository userRepository;
    @Mock UserNotificationSettingRepository notificationSettingRepository;

    @InjectMocks FcmService fcmService;

    private static final String TITLE = "제목";
    private static final String BODY = "본문";

    private FirebaseMessaging firebaseMessaging;

    @BeforeEach
    void setUp() {
        firebaseMessaging = mock(FirebaseMessaging.class);
    }

    // ---------- 헬퍼 ----------

    private User user(Long id) {
        User u = mock(User.class);
        given(u.getId()).willReturn(id);
        given(userRepository.findById(id)).willReturn(Optional.of(u));
        return u;
    }

    private void givenSetting(User user, boolean poll, boolean settlement, boolean activity) {
        UserNotificationSetting setting = mock(UserNotificationSetting.class);
        given(setting.isPollNotification()).willReturn(poll);
        given(setting.isSettlementNotification()).willReturn(settlement);
        given(setting.isActivityNotification()).willReturn(activity);
        given(notificationSettingRepository.findByUser(user)).willReturn(Optional.of(setting));
    }

    private void givenTokens(User user, String... tokens) {
        List<FcmToken> list = new java.util.ArrayList<>();
        for (String t : tokens) {
            FcmToken token = mock(FcmToken.class);
            given(token.getToken()).willReturn(t);
            list.add(token);
        }
        given(fcmTokenRepository.findByUser(user)).willReturn(list);
    }

    // Message의 data/token/notification은 패키지 전용 접근이라 리플렉션으로 읽는다
    @SuppressWarnings("unchecked")
    private Map<String, String> dataOf(Message message) {
        return (Map<String, String>) ReflectionTestUtils.invokeMethod(message, "getData");
    }

    private String tokenOf(Message message) {
        return (String) ReflectionTestUtils.invokeMethod(message, "getToken");
    }

    private String notificationField(Message message, String field) {
        Object notification = ReflectionTestUtils.invokeMethod(message, "getNotification");
        return (String) ReflectionTestUtils.getField(notification, field);
    }

    private List<Message> sentMessages(MockedStatic<FirebaseMessaging> firebase, int expectedCount)
            throws FirebaseMessagingException {
        ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
        verify(firebaseMessaging, times(expectedCount)).send(captor.capture());
        return captor.getAllValues();
    }

    // ---------- 메시지 만들기 ----------

    @Test
    @DisplayName("메시지: 제목과 본문은 그대로, data가 함께 담긴다")
    void buildMessage_withData() {
        Message message = FcmService.buildMessage("tok", TITLE, BODY, PushData.poll(10L));

        assertThat(tokenOf(message)).isEqualTo("tok");
        assertThat(notificationField(message, "title")).isEqualTo(TITLE);
        assertThat(notificationField(message, "body")).isEqualTo(BODY);
        assertThat(dataOf(message)).isEqualTo(Map.of("type", "POLL", "pollId", "10"));
    }

    @Test
    @DisplayName("메시지: data가 없거나 비어 있으면 data 없이 만들어진다 (sendToAll 등)")
    void buildMessage_withoutData() {
        Message empty = FcmService.buildMessage("tok", TITLE, BODY, Map.of());
        Message nul = FcmService.buildMessage("tok", TITLE, BODY, null);

        assertThat(dataOf(empty)).isNullOrEmpty();
        assertThat(dataOf(nul)).isNullOrEmpty();
        assertThat(notificationField(empty, "title")).isEqualTo(TITLE);
        assertThat(notificationField(nul, "body")).isEqualTo(BODY);
    }

    // ---------- 전송 경로 (FirebaseMessaging 정적 호출을 대체) ----------

    @Test
    @DisplayName("투표 알림: 알림 ON인 유저의 모든 기기에 data가 담겨 전송되고, OFF이거나 설정이 없으면 보내지 않는다")
    void pollNotification_sentWithData_onlyToEnabledUsers() throws Exception {
        User on = user(1L);
        User off = user(2L);
        User noSetting = user(3L);
        givenSetting(on, true, false, false);
        givenSetting(off, false, true, true);
        given(notificationSettingRepository.findByUser(noSetting)).willReturn(Optional.empty());
        givenTokens(on, "T1", "T2"); // 기기 2대
        givenTokens(off, "T3");
        given(userRepository.findAll()).willReturn(List.of(on, off, noSetting));

        try (MockedStatic<FirebaseMessaging> firebase = mockStatic(FirebaseMessaging.class)) {
            firebase.when(FirebaseMessaging::getInstance).thenReturn(firebaseMessaging);

            fcmService.sendPollNotification(TITLE, BODY, PushData.poll(10L));

            List<Message> sent = sentMessages(firebase, 2);
            assertThat(sent).extracting(this::tokenOf).containsExactlyInAnyOrder("T1", "T2");
            assertThat(sent).allSatisfy(message -> {
                assertThat(dataOf(message)).isEqualTo(PushData.poll(10L));
                assertThat(notificationField(message, "title")).isEqualTo(TITLE);
                assertThat(notificationField(message, "body")).isEqualTo(BODY);
            });
        }
    }

    @Test
    @DisplayName("정산 알림: 정산 알림 ON이면 정산 data로 전송, OFF면 보내지 않는다")
    void settlementNotification_sentWithData_respectsSetting() throws Exception {
        User on = user(1L);
        User off = user(2L);
        givenSetting(on, false, true, false);
        givenSetting(off, true, false, true);
        givenTokens(on, "T1");
        givenTokens(off, "T2");

        try (MockedStatic<FirebaseMessaging> firebase = mockStatic(FirebaseMessaging.class)) {
            firebase.when(FirebaseMessaging::getInstance).thenReturn(firebaseMessaging);

            fcmService.sendSettlementNotification(1L, TITLE, BODY, PushData.settlement(5L, 3L));
            fcmService.sendSettlementNotification(2L, TITLE, BODY, PushData.settlement(5L, 3L));

            List<Message> sent = sentMessages(firebase, 1);
            assertThat(tokenOf(sent.get(0))).isEqualTo("T1");
            assertThat(dataOf(sent.get(0))).isEqualTo(
                    Map.of("type", "SETTLEMENT", "activityId", "5", "transportGroupId", "3"));
        }
    }

    @Test
    @DisplayName("활동 알림: 활동 알림 ON이면 활동 data로 전송, OFF면 보내지 않는다")
    void activityNotification_sentWithData_respectsSetting() throws Exception {
        User on = user(1L);
        User off = user(2L);
        givenSetting(on, false, false, true);
        givenSetting(off, true, true, false);
        givenTokens(on, "T1");
        givenTokens(off, "T2");

        try (MockedStatic<FirebaseMessaging> firebase = mockStatic(FirebaseMessaging.class)) {
            firebase.when(FirebaseMessaging::getInstance).thenReturn(firebaseMessaging);

            fcmService.sendActivityNotificationToUser(1L, TITLE, BODY, PushData.activity(77L));
            fcmService.sendActivityNotificationToUser(2L, TITLE, BODY, PushData.activity(77L));

            List<Message> sent = sentMessages(firebase, 1);
            assertThat(tokenOf(sent.get(0))).isEqualTo("T1");
            assertThat(dataOf(sent.get(0))).isEqualTo(Map.of("type", "ACTIVITY", "activityId", "77"));
        }
    }

    @Test
    @DisplayName("sendToAll: 기존처럼 data 없이 제목과 본문만 전송한다")
    void sendToAll_withoutData() throws Exception {
        FcmToken token = mock(FcmToken.class);
        given(token.getToken()).willReturn("T1");
        given(fcmTokenRepository.findAll()).willReturn(List.of(token));

        try (MockedStatic<FirebaseMessaging> firebase = mockStatic(FirebaseMessaging.class)) {
            firebase.when(FirebaseMessaging::getInstance).thenReturn(firebaseMessaging);

            fcmService.sendToAll(TITLE, BODY);

            List<Message> sent = sentMessages(firebase, 1);
            assertThat(dataOf(sent.get(0))).isNullOrEmpty();
            assertThat(notificationField(sent.get(0), "title")).isEqualTo(TITLE);
        }
    }

    @Test
    @DisplayName("전송 대상이 없으면 FirebaseMessaging을 호출하지 않는다")
    void noTokens_noSend() throws Exception {
        User on = user(1L);
        givenSetting(on, true, true, true);
        givenTokens(on); // 토큰 없음

        try (MockedStatic<FirebaseMessaging> firebase = mockStatic(FirebaseMessaging.class)) {
            firebase.when(FirebaseMessaging::getInstance).thenReturn(firebaseMessaging);

            fcmService.sendSettlementNotification(1L, TITLE, BODY, PushData.settlement(1L, 1L));

            verify(firebaseMessaging, never()).send(any(Message.class));
        }
    }
}
