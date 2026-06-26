package com.smash.api.assignment;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AvailabilityResponse {

    private Long groupId;
    private DayOfWeek dayOfWeek;
    private TimeSlot timeSlot;
    private String label;
}
