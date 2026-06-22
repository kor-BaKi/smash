package com.smash.service;

import java.util.List;

public record ConfirmResult(int assignedCount, List<SkippedMember> skipped) {
}
