package com.smash.domain.group;

import java.time.LocalTime;

public enum TimeSlot {
    SLOT_13_15(LocalTime.of(13, 0)),
    SLOT_15_17(LocalTime.of(15, 0));

    private final LocalTime startTime;

    TimeSlot(LocalTime startTime) {
        this.startTime = startTime;
    }

    // D-1 voteClosed 판정 기준: activityDate + 이 시각.
    public LocalTime startTime() {
        return startTime;
    }
}
