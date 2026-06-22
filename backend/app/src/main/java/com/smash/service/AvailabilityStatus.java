package com.smash.service;

import com.smash.domain.group.Group;
import java.util.List;

public record AvailabilityStatus(List<Group> groups, boolean assigned, Long assignedGroupId) {
}
