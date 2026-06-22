package com.smash.api.admin;

import jakarta.validation.constraints.NotNull;

public record LeaderAssignRequest(@NotNull Long leaderUserId) {
}
