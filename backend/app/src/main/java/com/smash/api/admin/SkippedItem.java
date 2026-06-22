package com.smash.api.admin;

import com.smash.service.SkippedMember;

public record SkippedItem(Long userId, String reason) {

    public static SkippedItem from(SkippedMember member) {
        return new SkippedItem(member.userId(), member.reason());
    }
}
