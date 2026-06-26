package com.smash.api.assignment;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.List;

@Getter
public class AssignmentConfirmRequest {

    @NotNull
    private String previewToken;

    @NotNull
    private List<Long> basedOnMemberIds;

    @NotNull
    private List<AssignmentItem> assignments;

    @Getter
    public static class AssignmentItem {
        private Long userId;
        private Long groupId;
    }
}
