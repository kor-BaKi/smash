package com.smash.service;

import java.util.List;

public record MemberAssignmentView(Long userId, String name, Long assignedGroupId, List<Long> availableGroupIds) {
}
