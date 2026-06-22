package com.smash.api.admin;

import com.smash.service.MemberUnassignedView;

public record MemberUnassignedItem(Long userId, String name, String reason) {

    public static MemberUnassignedItem from(MemberUnassignedView view) {
        return new MemberUnassignedItem(view.userId(), view.name(), view.reason().name());
    }
}
