package com.smash.api.attendent;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class AttendanceResponse { // 조별 충족 현황. 조 정보 및 부원별 충족 결과

    private Long groupId;
    private String groupLabel;
    private int year;
    private int month;
    private int guaranteedCount;
    private List<MemberAttendance> members;

    @Builder
    public static class MemberAttendance {
        private Long userId;
        private String name;
        private int fulfilled;  // 참여 횟수
        private int guaranteed; // 보장된 활동 횟수 (보통 4)
        private int shortfall; // 미달 횟수 (불참 횟수)
        private boolean isShortfall;

        @JsonProperty("userId")
        public Long getUserId() { return userId; }

        @JsonProperty("name")
        public String getName() { return name; }

        @JsonProperty("fulfilled")
        public int getFulfilled() { return fulfilled; }

        @JsonProperty("guaranteed")
        public int getGuaranteed() { return guaranteed; }

        @JsonProperty("shortfall")
        public int getShortfall() { return shortfall; }

        @JsonProperty("isShortfall")
        public boolean getIsShortfall() { return isShortfall; }
    }
}
