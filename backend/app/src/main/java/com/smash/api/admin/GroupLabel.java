package com.smash.api.admin;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;

// "월 1-3시" 같은 노출용 라벨은 저장하지 않고 응답 시점에 계산한다 (B-1/B-2/C-1/C-2 스펙).
// api.member에서도 같은 라벨이 필요해서 public으로 공개.
public final class GroupLabel {

    private GroupLabel() {
    }

    public static String of(DayOfWeek dayOfWeek, TimeSlot timeSlot) {
        return dayLabel(dayOfWeek) + " " + timeLabel(timeSlot);
    }

    private static String dayLabel(DayOfWeek dayOfWeek) {
        return switch (dayOfWeek) {
            case MON -> "월";
            case TUE -> "화";
            case WED -> "수";
            case THU -> "목";
            case FRI -> "금";
        };
    }

    private static String timeLabel(TimeSlot timeSlot) {
        return switch (timeSlot) {
            case SLOT_13_15 -> "1-3시";
            case SLOT_15_17 -> "3-5시";
        };
    }
}
