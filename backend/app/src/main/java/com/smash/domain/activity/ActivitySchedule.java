package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 스케줄러가 매일 자정 is_active=true인 슬롯만 읽어 그날의 Activity를 생성한다 (단계 4 구현 예정).
@Entity
@Table(name = "activity_schedule", uniqueConstraints = @UniqueConstraint(columnNames = {"day_of_week", "time_slot"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ActivitySchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    private DayOfWeek dayOfWeek;

    @Enumerated(EnumType.STRING)
    @Column(name = "time_slot", nullable = false, length = 20)
    private TimeSlot timeSlot;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Builder
    private ActivitySchedule(DayOfWeek dayOfWeek, TimeSlot timeSlot, boolean active) {
        this.dayOfWeek = dayOfWeek;
        this.timeSlot = timeSlot;
        this.active = active;
    }

    public static ActivitySchedule create(DayOfWeek dayOfWeek, TimeSlot timeSlot, boolean active) {
        return ActivitySchedule.builder().dayOfWeek(dayOfWeek).timeSlot(timeSlot).active(active).build();
    }
}
