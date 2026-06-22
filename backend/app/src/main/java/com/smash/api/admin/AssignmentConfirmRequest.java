package com.smash.api.admin;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record AssignmentConfirmRequest(
        // 서버는 별도로 저장한 게 없어 값을 대조하지 않는다. preview~confirm 정합성 검증의
        // 핵심은 basedOnMemberIds 비교 쪽이고, 이 토큰은 클라이언트 추적용으로만 받는다.
        @NotBlank String previewToken,
        @NotEmpty List<Long> basedOnMemberIds,
        @NotEmpty List<@Valid AssignmentItem> assignments
) {

    public record AssignmentItem(@NotNull Long userId, @NotNull Long groupId) {
    }
}
