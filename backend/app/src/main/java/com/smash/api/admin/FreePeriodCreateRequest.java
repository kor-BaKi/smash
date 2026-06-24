package com.smash.api.admin;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record FreePeriodCreateRequest(
        String name,
        @NotNull(message = "시작일은 필수입니다.") LocalDate startDate,
        @NotNull(message = "종료일은 필수입니다.") LocalDate endDate
) {
}
