package com.smash.domain.activity;


import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "activity_schedule")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ActivitySchedule { // 스케줄러가 자동으로 매일 활동을 생성하는 규칙


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DayOfWeek dayOfWeek;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TimeSlot timeSlot;

    @Column(nullable = false)
    private Boolean isActive;

    @Builder
    public ActivitySchedule(DayOfWeek dayOfWeek, TimeSlot timeSlot, Boolean isActive) {
        this.dayOfWeek = dayOfWeek;
        this.timeSlot = timeSlot;
        this.isActive = isActive;
    }

    public void updateActive(boolean isActive) {
        this.isActive = isActive;
    }

}
