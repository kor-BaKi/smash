package com.smash.api.activity;

import com.smash.service.ActivityParticipants;
import java.util.List;

public record ActivityParticipantsItem(
        List<ParticipantItem> regular,
        List<ParticipantItem> carryover,
        List<ParticipantItem> otherGroup,
        List<ParticipantItem> freeAttend,
        List<ParticipantItem> absent
) {

    public static ActivityParticipantsItem from(ActivityParticipants participants) {
        return new ActivityParticipantsItem(
                participants.regular().stream().map(ParticipantItem::from).toList(),
                participants.carryover().stream().map(ParticipantItem::from).toList(),
                participants.otherGroup().stream().map(ParticipantItem::from).toList(),
                participants.freeAttend().stream().map(ParticipantItem::from).toList(),
                participants.absent().stream().map(ParticipantItem::from).toList()
        );
    }
}
