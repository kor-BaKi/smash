package com.smash.service;

import java.util.List;

public record MemberAvailabilityInput(Long userId, List<Long> availableGroupIds) {
}
