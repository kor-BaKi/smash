package com.smash.api.admin;

import com.smash.domain.activity.ActivityType;

public record ActivityUpdateRequest(Boolean isCancelled, ActivityType activityType) {
}
