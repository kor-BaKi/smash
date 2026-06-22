package com.smash.service;

import java.time.LocalDate;

public record CarryoverCandidate(Long activityId, LocalDate date, CandidateStatus status) {
}
