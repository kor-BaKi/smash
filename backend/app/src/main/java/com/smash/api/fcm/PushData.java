package com.smash.api.fcm;

import java.util.Map;
import java.util.Objects;

// 푸시 알림에 함께 보내는 data 페이로드.
// 앱이 알림을 눌렀을 때 어느 화면으로 이동할지 알 수 있게 한다.
// FCM data 값은 모두 문자열이어야 하므로 id도 문자열로 만든다. (앱에서 파싱)
// 키는 FCM 예약어(from, notification, message_type, google*, gcm*)를 피한다.
public final class PushData {

    public static final String KEY_TYPE = "type";
    public static final String KEY_POLL_ID = "pollId";
    public static final String KEY_ACTIVITY_ID = "activityId";
    public static final String KEY_TRANSPORT_GROUP_ID = "transportGroupId";

    public static final String TYPE_POLL = "POLL";
    public static final String TYPE_SETTLEMENT = "SETTLEMENT";
    public static final String TYPE_ACTIVITY = "ACTIVITY";

    private PushData() {
    }

    // 투표 생성 알림 → 투표 상세
    public static Map<String, String> poll(Long pollId) {
        return Map.of(
                KEY_TYPE, TYPE_POLL,
                KEY_POLL_ID, id(pollId));
    }

    // 정산 요청 알림 → 정산 상세 (정산 조회 API가 활동 id와 호차 id를 모두 필요로 한다)
    public static Map<String, String> settlement(Long activityId, Long transportGroupId) {
        return Map.of(
                KEY_TYPE, TYPE_SETTLEMENT,
                KEY_ACTIVITY_ID, id(activityId),
                KEY_TRANSPORT_GROUP_ID, id(transportGroupId));
    }

    // 활동 마감 임박 알림 → 활동 상세
    public static Map<String, String> activity(Long activityId) {
        return Map.of(
                KEY_TYPE, TYPE_ACTIVITY,
                KEY_ACTIVITY_ID, id(activityId));
    }

    private static String id(Long value) {
        return String.valueOf(Objects.requireNonNull(value, "푸시 data의 id는 null일 수 없습니다."));
    }
}
