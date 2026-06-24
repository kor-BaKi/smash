package com.smash.domain.group;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "club_groups", uniqueConstraints = @UniqueConstraint(columnNames = {"day_of_week", "time_slot"}))
@Getter
@NoArgsConstructor
public class Group {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DayOfWeek dayOfWeek;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TimeSlot timeSlot;

    private Long leaderUserId; // 조장

    @Builder
    public Group(DayOfWeek dayOfWeek, TimeSlot timeSlot) {
        this.dayOfWeek = dayOfWeek;
        this.timeSlot = timeSlot;
    }

    public void assignLeader(Long leaderUserId) {
        this.leaderUserId = leaderUserId;
    }

    public String getLabel() {
        return dayOfWeek.getLabel() + " " + timeSlot.getLabel();
    }

}
