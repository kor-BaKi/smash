package com.smash.api.group;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.List;

@Getter
public class GroupRequest {

    @NotNull(message = "조 목록을 입력해주세요.")
    private List<GroupItem> groups;

    @Getter
    public static class GroupItem {

        @NotNull(message = "요일을 입력해주세요.")
        private DayOfWeek dayOfWeek;

        @NotNull(message = "시간대를 입력해주세요.")
        private TimeSlot timeSlot;
    }

    @Getter
    public static class LeaderRequest {

        @NotNull(message = "조장 userId를 입력해주세요.")
        private Long leaderUserId;
    }

}
