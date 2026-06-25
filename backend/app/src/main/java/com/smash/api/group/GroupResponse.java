package com.smash.api.group;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class GroupResponse {

    private Long id;
    private DayOfWeek dayOfWeek;
    private TimeSlot timeSlot;
    private String label;
    private Long leaderUserId;
    private int memberCount;

    public static GroupResponse of(Group group, int memberCount) {
        return GroupResponse.builder()
                .id(group.getId())
                .dayOfWeek(group.getDayOfWeek())
                .timeSlot(group.getTimeSlot())
                .label(group.getLabel())
                .leaderUserId(group.getLeaderUserId())
                .memberCount(memberCount)
                .build();
    }
}
