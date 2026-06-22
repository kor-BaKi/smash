package com.smash.api.admin;

import com.smash.service.GroupCount;

public record GroupDistributionItem(Long groupId, String label, int count) {

    public static GroupDistributionItem from(GroupCount groupCount) {
        return new GroupDistributionItem(
                groupCount.groupId(),
                GroupLabel.of(groupCount.dayOfWeek(), groupCount.timeSlot()),
                groupCount.count());
    }
}
