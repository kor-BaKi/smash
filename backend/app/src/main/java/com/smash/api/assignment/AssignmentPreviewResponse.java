package com.smash.api.assignment;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class AssignmentPreviewResponse {

    private String previewToken;
    private List<Long> basedOnMemberIds;
    private List<AssignmentItem> assignments; // 배정 성공한 부원 한 명의 결과
    private List<UnassignedItem> unassigned; // 배정 못 한 부원
    private List<GroupDistribution> groupDistribution; // 조별 배정 인원 분포 (몇명인지)


    @Getter
    @Builder
    public static class AssignmentItem {
        private Long userId;
        private String name;
        private Long assignedGroupId; // 배정된 조 (ex. 월 1-3)
        private List<Long> availableGroupIds; // 가능한 조 목록 (ex. 월 1-3, 수 3-5, 금 3-5)
    }

    @Getter
    @Builder
    public static class UnassignedItem {
        private Long userId;
        private String name;
        private String reason;
    }

    @Getter
    @Builder
    public static class GroupDistribution {
        private Long groupId;
        private String label;
        private int count;
    }

}
