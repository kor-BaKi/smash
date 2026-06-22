package com.smash.domain.participation;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

// SMASH의 "심장" - 출석/이월/충족 전부 이 테이블에서 계산한다 (별도 저장 없음).
@Entity
@Table(name = "participation", uniqueConstraints = @UniqueConstraint(columnNames = {"activity_id", "user_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Participation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "activity_id", nullable = false)
    private Long activityId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ParticipationType type;

    // type=CARRYOVER일 때만 채워짐: "오늘 자격을 어느 활동으로 옮겼는지".
    @Column(name = "carryover_target_activity_id")
    private Long carryoverTargetActivityId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Builder
    private Participation(Long activityId, Long userId, ParticipationType type, Long carryoverTargetActivityId) {
        this.activityId = activityId;
        this.userId = userId;
        this.type = type;
        this.carryoverTargetActivityId = carryoverTargetActivityId;
    }

    public static Participation create(Long activityId, Long userId, ParticipationType type, Long carryoverTargetActivityId) {
        return Participation.builder()
                .activityId(activityId)
                .userId(userId)
                .type(type)
                .carryoverTargetActivityId(carryoverTargetActivityId)
                .build();
    }

    // D-2: (activity_id,user_id) UNIQUE upsert. 이미 응답이 있으면 새로 만들지 않고 덮어쓴다.
    public void update(ParticipationType type, Long carryoverTargetActivityId) {
        this.type = type;
        this.carryoverTargetActivityId = carryoverTargetActivityId;
    }
}
