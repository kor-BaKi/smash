package com.smash.api.member;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record AvailabilitySubmitRequest(@NotEmpty List<Long> groupIds) {
}
