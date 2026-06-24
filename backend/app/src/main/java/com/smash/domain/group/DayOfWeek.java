package com.smash.domain.group;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum DayOfWeek {
    MON("월"), TUE("화"), WED("수"), THU("목"), FRI("금");

    private final String label;
}
