package com.smash.api.fcm;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PushDataTest {

    @Test
    @DisplayName("투표: type=POLL, pollId는 문자열")
    void poll_payload() {
        assertThat(PushData.poll(10L)).isEqualTo(Map.of(
                "type", "POLL",
                "pollId", "10"));
    }

    @Test
    @DisplayName("정산: type=SETTLEMENT, 활동 id와 호차 id 모두 문자열")
    void settlement_payload() {
        assertThat(PushData.settlement(5L, 3L)).isEqualTo(Map.of(
                "type", "SETTLEMENT",
                "activityId", "5",
                "transportGroupId", "3"));
    }

    @Test
    @DisplayName("활동: type=ACTIVITY, activityId는 문자열")
    void activity_payload() {
        assertThat(PushData.activity(77L)).isEqualTo(Map.of(
                "type", "ACTIVITY",
                "activityId", "77"));
    }

    @Test
    @DisplayName("앱에서 id를 Long으로 되돌려 파싱할 수 있다")
    void ids_roundTripAsLong() {
        assertThat(Long.parseLong(PushData.poll(Long.MAX_VALUE).get("pollId")))
                .isEqualTo(Long.MAX_VALUE);
        assertThat(Long.parseLong(PushData.settlement(1L, 2L).get("transportGroupId")))
                .isEqualTo(2L);
    }

    @Test
    @DisplayName("FCM 예약 키(from, notification, message_type, google*, gcm*)를 쓰지 않는다")
    void keys_avoidFcmReservedWords() {
        List<Map<String, String>> payloads = List.of(
                PushData.poll(1L), PushData.settlement(1L, 1L), PushData.activity(1L));

        for (Map<String, String> payload : payloads) {
            assertThat(payload.keySet())
                    .doesNotContain("from", "notification", "message_type")
                    .noneMatch(key -> key.startsWith("google") || key.startsWith("gcm"));
        }
    }

    @Test
    @DisplayName("id가 null이면 전송 전에 바로 실패한다 (FCM에 null 값을 보내지 않는다)")
    void nullId_rejected() {
        assertThatThrownBy(() -> PushData.poll(null)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> PushData.settlement(null, 1L)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> PushData.settlement(1L, null)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> PushData.activity(null)).isInstanceOf(NullPointerException.class);
    }
}
