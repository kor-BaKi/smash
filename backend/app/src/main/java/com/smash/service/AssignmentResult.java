package com.smash.service;

import java.util.List;
import java.util.Map;

public record AssignmentResult(
        List<Assignment> assignments,
        List<Unassigned> unassigned,
        Map<Long, Integer> groupDistribution
) {
}
