package com.smash.domain.user;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "user_notification_setting")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserNotificationSetting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private boolean pollNotification = true;       // 투표 알림

    @Column(nullable = false)
    private boolean settlementNotification = true; // 정산 알림

    @Column(nullable = false)
    private boolean activityNotification = true;   // 활동 알림

    @Builder
    public UserNotificationSetting(User user) {
        this.user = user;
        this.pollNotification = true;
        this.settlementNotification = true;
        this.activityNotification = true;
    }

    public void update(
            boolean pollNotification,
            boolean settlementNotification,
            boolean activityNotification
    ) {
        this.pollNotification = pollNotification;
        this.settlementNotification = settlementNotification;
        this.activityNotification = activityNotification;
    }
}