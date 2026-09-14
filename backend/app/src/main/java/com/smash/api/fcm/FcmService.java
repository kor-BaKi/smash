package com.smash.api.fcm;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.smash.domain.user.FcmToken;
import com.smash.domain.user.FcmTokenRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;

    // FCM 토큰 저장/업데이트
    @Transactional
    public void saveToken(Long userId, String token, String deviceType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        // 이미 존재하는 토큰이면 업데이트
        fcmTokenRepository.findByToken(token).ifPresentOrElse(
                fcmToken -> fcmToken.updateToken(token),
                () -> fcmTokenRepository.save(
                        FcmToken.builder()
                                .user(user)
                                .token(token)
                                .deviceType(deviceType)
                                .build()
                )
        );
    }

    // 특정 유저에게 알림 전송
    public void sendToUser(Long userId, String title, String body) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));

        List<FcmToken> tokens = fcmTokenRepository.findByUser(user);
        for (FcmToken fcmToken : tokens) {
            sendMessage(fcmToken.getToken(), title, body);
        }
    }

    // 전체 유저에게 알림 전송
    public void sendToAll(String title, String body) {
        List<FcmToken> tokens = fcmTokenRepository.findAll();
        for (FcmToken fcmToken : tokens) {
            sendMessage(fcmToken.getToken(), title, body);
        }
    }

    // FCM 메시지 전송
    private void sendMessage(String token, String title, String body) {
        try {
            Message message = Message.builder()
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .setToken(token)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("FCM 전송 성공 : {}", response);
        } catch (FirebaseMessagingException e) {
            log.error("FCM 전송 실패 - token: {}, error: {}", token, e.getMessage());
        }
    }

    // 로그아웃 시 토큰 삭제
    @Transactional
    public void deleteToken(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다."));
        fcmTokenRepository.deleteByUser(user);
    }
}
