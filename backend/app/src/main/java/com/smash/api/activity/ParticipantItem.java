package com.smash.api.activity;

import com.smash.service.ParticipantView;

public record ParticipantItem(Long userId, String name) {

    public static ParticipantItem from(ParticipantView view) {
        return new ParticipantItem(view.userId(), view.name());
    }
}
