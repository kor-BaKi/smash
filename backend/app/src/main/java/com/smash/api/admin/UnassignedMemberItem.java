package com.smash.api.admin;

import com.smash.service.UnassignedMemberView;
import java.util.List;

public record UnassignedMemberItem(Long userId, String name, List<Long> availableGroupIds) {

    public static UnassignedMemberItem from(UnassignedMemberView view) {
        return new UnassignedMemberItem(view.userId(), view.name(), view.availableGroupIds());
    }
}
