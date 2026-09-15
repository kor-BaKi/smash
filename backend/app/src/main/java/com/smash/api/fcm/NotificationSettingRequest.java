package com.smash.api.fcm;

import lombok.Getter;

@Getter
public class NotificationSettingRequest {
    private boolean pollNotification;
    private boolean settlementNotification;
    private boolean activityNotification;
}
