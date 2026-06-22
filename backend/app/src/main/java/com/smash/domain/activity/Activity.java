package com.smash.domain.activity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

// 활동 = 투표 단위. 스케줄러가 매일 자정 생성(created_by=AUTO), 조회 시 없으면 lazy 보정 생성도 동일 경로 사용.
@Entity
@Table(name = "activity", uniqueConstraints = @UniqueConstraint(columnNames = {"group_id", "activity_date"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Activity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_id", nullable = false)
    private Long groupId;

    @Column(name = "activity_date", nullable = false)
    private LocalDate activityDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_type", nullable = false, length = 20)
    private ActivityType activityType;

    @Column(name = "is_cancelled", nullable = false)
    private boolean cancelled;

    @Enumerated(EnumType.STRING)
    @Column(name = "created_by", nullable = false, length = 10)
    private CreatedBy createdBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private Activity(Long groupId, LocalDate activityDate, ActivityType activityType, CreatedBy createdBy) {
        this.groupId = groupId;
        this.activityDate = activityDate;
        this.activityType = activityType;
        this.cancelled = false;
        this.createdBy = createdBy;
    }

    public static Activity create(Long groupId, LocalDate activityDate, ActivityType activityType, CreatedBy createdBy) {
        return Activity.builder()
                .groupId(groupId)
                .activityDate(activityDate)
                .activityType(activityType)
                .createdBy(createdBy)
                .build();
    }

    // D-7: 과거 응답은 삭제하지 않고 활동 자체만 수정한다.
    public void updateCancelled(boolean cancelled) {
        this.cancelled = cancelled;
    }

    public void updateActivityType(ActivityType activityType) {
        this.activityType = activityType;
    }
}
