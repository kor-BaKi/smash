package com.smash.api.admin;

import com.smash.service.AssignmentPreviewResult;
import java.util.List;

public record AssignmentPreviewResponse(
        String previewToken,
        List<Long> basedOnMemberIds,
        List<MemberAssignmentItem> assignments,
        List<MemberUnassignedItem> unassigned,
        List<GroupDistributionItem> groupDistribution
) {

    public static AssignmentPreviewResponse from(AssignmentPreviewResult result) {
        return new AssignmentPreviewResponse(
                result.previewToken(),
                result.basedOnMemberIds(),
                result.assignments().stream().map(MemberAssignmentItem::from).toList(),
                result.unassigned().stream().map(MemberUnassignedItem::from).toList(),
                result.groupDistribution().stream().map(GroupDistributionItem::from).toList()
        );
    }
}
