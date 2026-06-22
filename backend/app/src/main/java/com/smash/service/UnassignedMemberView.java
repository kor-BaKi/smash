package com.smash.service;

import java.util.List;

public record UnassignedMemberView(Long userId, String name, List<Long> availableGroupIds) {
}
