package com.smash.api.fcm;

import com.google.firebase.messaging.*;
import com.smash.domain.user.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;
    private final UserNotificationSettingRepository notificationSettingRepository;

    // FCM 토큰 저장/업데이트
    @Transactional
    public void saveToken(Long userId, String token, String deviceType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        // 알림 설정 기본값 생성 (최초 로그인 시)
        notificationSettingRepository.findByUser(user).orElseGet(() ->
                notificationSettingRepository.save(
                        UserNotificationSetting.builder().user(user).build()
                )
        );

        fcmTokenRepository.findByToken(token).ifPresentOrElse(
                fcmToken -> fcmToken.assignTo(user, deviceType),
                () -> fcmTokenRepository.save(
                        FcmToken.builder().user(user).token(token).deviceType(deviceType).build()
                )
        );

    }

    // 특정 유저에게 알림 전송
    // data: 앱이 알림을 눌렀을 때 이동할 화면 정보 (PushData 참고, 값은 모두 문자열)
    public void sendToUser(Long userId, String title, String body, Map<String, String> data) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        List<FcmToken> tokens = fcmTokenRepository.findByUser(user);
        for (FcmToken fcmToken : tokens) {
            sendMessage(fcmToken.getToken(), title, body, data);
        }
    }

    // 투표 알림 - 전체 유저 중 투표 알림 ON인 유저에게만 전송
    public void sendPollNotification(String title, String body, Map<String, String> data) {
        List<User> users = userRepository.findAll();
        for (User user : users) {
            notificationSettingRepository.findByUser(user).ifPresent(setting -> {
                if (setting.isPollNotification()) {
                    sendToUser(user.getId(), title, body, data);
                }
            });
        }
    }

    // 정산 알림 - 특정 유저가 정산 알림 ON이면 전송
    public void sendSettlementNotification(Long userId, String title, String body,
                                           Map<String, String> data) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        notificationSettingRepository.findByUser(user).ifPresent(setting -> {
            if (setting.isSettlementNotification()) {
                sendToUser(userId, title, body, data);
            }
        });
    }

    // 활동 알림 - 특정 유저가 활동 알림 ON이면 전송
    public void sendActivityNotificationToUser(Long userId, String title, String body,
                                               Map<String, String> data) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        notificationSettingRepository.findByUser(user).ifPresent(setting -> {
            if (setting.isActivityNotification()) {
                sendToUser(userId, title, body, data);
            }
        });
    }

    // 전체 유저에게 알림 전송 (설정 무관)
    public void sendToAll(String title, String body) {
        List<FcmToken> tokens = fcmTokenRepository.findAll();
        for (FcmToken fcmToken : tokens) {
            sendMessage(fcmToken.getToken(), title, body, Map.of());
        }
    }

    // 제목과 본문(notification)은 그대로 두고, data가 있으면 함께 담는다
    static Message buildMessage(String token, String title, String body, Map<String, String> data) {
        Message.Builder builder = Message.builder()
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .setToken(token);

        if (data != null && !data.isEmpty()) {
            builder.putAllData(data);
        }
        return builder.build();
    }

    // FCM 메시지 전송
    private void sendMessage(String token, String title, String body, Map<String, String> data) {
        try {
            Message message = buildMessage(token, title, body, data);

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("FCM 전송 성공: {}", response);
        } catch (FirebaseMessagingException e) {
            MessagingErrorCode code = e.getMessagingErrorCode();
            log.error("FCM 전송 실패 - token: {}, code: {}, error: {}",
                    maskToken(token), code, e.getMessage());

            // 앱 삭제·재설치로 더 이상 유효하지 않은 토큰은 정리한다
            if (code == MessagingErrorCode.UNREGISTERED) {
                fcmTokenRepository.deleteByToken(token);
            }
        }
    }

    private String maskToken(String token) {
        if (token == null || token.length() <= 8) return "***";
        return token.substring(0, 8) + "...";
    }

    // 로그아웃 시 토큰 삭제
    @Transactional
    public void deleteToken(Long userId, String token) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));
        if (token == null || token.isBlank()) {
            fcmTokenRepository.deleteByUser(user);
        } else {
            fcmTokenRepository.deleteByUserAndToken(user, token);

        }
    }
}