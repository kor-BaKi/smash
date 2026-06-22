package com.smash.api.member;

import com.smash.service.CarryoverCandidate;
import java.time.LocalDate;

public record CarryoverCandidateItem(Long targetActivityId, LocalDate date, String status) {

    public static CarryoverCandidateItem from(CarryoverCandidate candidate) {
        return new CarryoverCandidateItem(candidate.activityId(), candidate.date(), candidate.status().name());
    }
}
