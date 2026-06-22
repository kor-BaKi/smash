package com.smash.api.admin;

import com.smash.service.ConfirmResult;
import java.util.List;

public record AssignmentConfirmResponse(int assignedCount, List<SkippedItem> skipped) {

    public static AssignmentConfirmResponse from(ConfirmResult result) {
        return new AssignmentConfirmResponse(
                result.assignedCount(), result.skipped().stream().map(SkippedItem::from).toList());
    }
}
