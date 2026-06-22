package com.smash.service;

import java.util.List;

public record AssignmentPreviewResult(
        String previewToken,
        List<Long> basedOnMemberIds,
        List<MemberAssignmentView> assignments,
        List<MemberUnassignedView> unassigned,
        List<GroupCount> groupDistribution
) {
}
