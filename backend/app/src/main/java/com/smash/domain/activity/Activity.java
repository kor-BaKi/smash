package com.smash.domain.activity;

import com.smash.domain.group.Group;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "activity", uniqueConstraints = @UniqueConstraint(columnNames = {"group_id", "activity_date"})) // 같은 조에 같은 날짜로 활동이 중복 생성되는 걸 DB 레벨에서 막습니다. 스케줄러가 실수로 두 번 실행돼도 중복이 생기지 않습니다.
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Activity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @Column(nullable = false)
    private LocalDate activityDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActivityType activityType;

    @Column(nullable = false)
    private boolean isCancelled = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CreatedBy createdBy;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public Activity(Group group, LocalDate activityDate, ActivityType activityType, CreatedBy createdBy) {
        this.group = group;
        this.activityDate = activityDate;
        this.activityType = activityType;
        this.createdBy = createdBy;
    }

    public void cancel(boolean isCancelled) { // 활동 취소
        this.isCancelled = isCancelled;
    }

    public void changeType(ActivityType activityType) { // 정규 <-> 자유 전환
        this.activityType = activityType;
    }

}
