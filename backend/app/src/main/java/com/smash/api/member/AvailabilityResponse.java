package com.smash.api.member;

import java.util.List;

public record AvailabilityResponse(List<AvailabilityItem> availabilities, boolean assigned, Long assignedGroupId) {
}
