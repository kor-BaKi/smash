package com.smash.api.activity;

import com.smash.service.ParticipationSummary;

public record ParticipationSummaryItem(int regular, int carryover, int otherGroup, int freeAttend, int absent) {

    public static ParticipationSummaryItem from(ParticipationSummary summary) {
        return new ParticipationSummaryItem(
                summary.regular(), summary.carryover(), summary.otherGroup(), summary.freeAttend(), summary.absent());
    }
}
