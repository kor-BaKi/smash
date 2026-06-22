package com.smash.api.admin;

import com.smash.service.ShortfallMember;

public record ShortfallItem(Long userId, String name, String groupLabel, int fulfilled, int guaranteed, int shortfall) {

    public static ShortfallItem from(ShortfallMember member) {
        return new ShortfallItem(
                member.userId(), member.name(),
                GroupLabel.of(member.groupDayOfWeek(), member.groupTimeSlot()),
                member.fulfilled(), member.guaranteed(), member.shortfall());
    }
}
