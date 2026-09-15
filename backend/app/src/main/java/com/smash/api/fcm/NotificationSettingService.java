package com.smash.api.fcm;

import com.smash.common.exception.BusinessException;
import com.smash.domain.user.User;
import com.smash.domain.user.UserNotificationSetting;
import com.smash.domain.user.UserNotificationSettingRepository;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationSettingService {

    private final UserNotificationSettingRepository notificationSettingRepository;
    private final UserRepository userRepository;

    // 알림 설정 조회
    @Transactional(readOnly = true)
    public NotificationSettingResponse getSetting(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."));

        UserNotificationSetting setting = notificationSettingRepository.findByUser(user)
                .orElseGet(() -> notificationSettingRepository.save(
                        UserNotificationSetting.builder().user(user).build()
                ));
        return NotificationSettingResponse.of(setting);
    }

    // 알림 설정 수정
    @Transactional
    public NotificationSettingResponse updateSetting(Long userId, NotificationSettingRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."));

        UserNotificationSetting setting = notificationSettingRepository.findByUser(user)
                .orElseGet(() -> notificationSettingRepository.save(
                        UserNotificationSetting.builder().user(user).build()
                ));

        setting.update(
                request.isPollNotification(),
                request.isSettlementNotification(),
                request.isActivityNotification()
        );

        return NotificationSettingResponse.of(setting);
    }

}
