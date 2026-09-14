package com.smash.domain.user;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "fcm_token")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FcmToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) // FetchType.LAZY : 토큰을 조회할 때 유저 정보를 즉시 가져오지 않고 필요할 때만 가져옴 (성능 최적화)
    @JoinColumn(name = "user_id", nullable = false)
    private User user; // 한 유저가 여러 기기 사용할 때 사용 (아이폰 + 갤럭시)

    @Column(nullable = false, unique = true) // unique인 이유 : 같은 기기에서 로그아웃 후 다른 계정으로 로그인하면 토큰이 다른 유저에게 중복 등록될 수 있습니다. unique 제약으로 이를 방지.
    private String token; // FCM 토큰 값.

    @Column(nullable = false)
    private String deviceType; // Android, IOS

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public FcmToken(User user, String token, String deviceType) {
        this.user = user;
        this.token = token;
        this.deviceType = deviceType;
    }

    public void updateToken(String token) {
        this.token = token;
    }
}

// [전체 흐름]
//  1. 유저가 앱 설치 → FCM 토큰 발급
//  2. 로그인 시 Flutter → 서버로 토큰 전송
//  3. 서버에서 FcmToken 테이블에 저장
//  4. 알림 발송 시:
//    → 유저 ID로 FcmToken 조회
//    → 토큰으로 FCM에 메시지 전송
//    → FCM이 해당 기기로 알림 전달