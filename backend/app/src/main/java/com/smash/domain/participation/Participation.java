package com.smash.domain.participation;

import com.smash.domain.activity.Activity;
import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "participation",
        uniqueConstraints = @UniqueConstraint(columnNames = {"activity_id", "user_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Participation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id", nullable = false)
    private Activity activity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ParticipationType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "carryover_target_activity_id")
    private Activity carryoverTarget;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @PrePersist // 처음 저장할 때 실행
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @PreUpdate // 수정할 때마다 자동 실행
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    @Builder
    public Participation(Activity activity, User user,
                         ParticipationType type, Activity carryoverTarget) {
        this.activity = activity;
        this.user = user;
        this.type = type;
        this.carryoverTarget = carryoverTarget;
    }

    public void updateType(ParticipationType type, Activity carryoverTarget) { // 부원이 재응답할 때 사용 ex. 참여 -> 불참으로 변경
        this.type = type;
        this.carryoverTarget = carryoverTarget;
    }
}