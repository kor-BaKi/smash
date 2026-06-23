package com.smash.api.admin;

import com.smash.service.GroupComparisonItem;

public record GroupComparisonResponseItem(
        Long groupId, String groupLabel, int guaranteed, int fulfilled, int shortfallMemberCount, double fulfillmentRate) {

    public static GroupComparisonResponseItem from(GroupComparisonItem item) {
        return new GroupComparisonResponseItem(
                item.groupId(), GroupLabel.of(item.dayOfWeek(), item.timeSlot()),
                item.guaranteed(), item.fulfilled(), item.shortfallMemberCount(), item.fulfillmentRate());
    }
}
