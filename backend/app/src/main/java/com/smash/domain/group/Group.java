package com.smash.domain.group;

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

// "group"/"groups" 둘 다 MySQL 8 예약어(GROUPS는 윈도우 함수 프레임 문법)라 club_groups로 회피.
@Entity
@Table(name = "club_groups", uniqueConstraints = @UniqueConstraint(columnNames = {"day_of_week", "time_slot"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Group {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    private DayOfWeek dayOfWeek;

    @Enumerated(EnumType.STRING)
    @Column(name = "time_slot", nullable = false, length = 20)
    private TimeSlot timeSlot;

    @Column(name = "leader_user_id")
    private Long leaderUserId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private Group(DayOfWeek dayOfWeek, TimeSlot timeSlot) {
        this.dayOfWeek = dayOfWeek;
        this.timeSlot = timeSlot;
    }

    public static Group create(DayOfWeek dayOfWeek, TimeSlot timeSlot) {
        return Group.builder().dayOfWeek(dayOfWeek).timeSlot(timeSlot).build();
    }

    // B-3: 기존 조장은 호출부에서 별도로 User.unassignLeader()로 해제한다.
    public void assignLeader(Long userId) {
        this.leaderUserId = userId;
    }
}
