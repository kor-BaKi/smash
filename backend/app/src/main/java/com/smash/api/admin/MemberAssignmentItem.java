package com.smash.api.admin;

import com.smash.service.MemberAssignmentView;
import java.util.List;

public record MemberAssignmentItem(Long userId, String name, Long assignedGroupId, List<Long> availableGroupIds) {

    public static MemberAssignmentItem from(MemberAssignmentView view) {
        return new MemberAssignmentItem(view.userId(), view.name(), view.assignedGroupId(), view.availableGroupIds());
    }
}
