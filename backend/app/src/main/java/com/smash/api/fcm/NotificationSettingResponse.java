package com.smash.api.fcm;

import com.smash.domain.user.UserNotificationSetting;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class NotificationSettingResponse {
    private boolean pollNotification;
    private boolean settlementNotification;
    private boolean activityNotification;

    public static NotificationSettingResponse of(UserNotificationSetting setting) {
        return NotificationSettingResponse.builder()
                .pollNotification(setting.isPollNotification())
                .settlementNotification(setting.isSettlementNotification())
                .activityNotification(setting.isActivityNotification())
                .build();
    }
}
