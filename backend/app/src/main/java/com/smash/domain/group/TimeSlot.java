package com.smash.domain.group;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum TimeSlot {
    SLOT_13_15("1-3시"), SLOT_15_17("3-5시");

    private final String label;
}
