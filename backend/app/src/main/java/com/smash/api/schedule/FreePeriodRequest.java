package com.smash.api.schedule;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class FreePeriodRequest {

    @NotNull(message = "시작일을 입력해주세요.")
    private LocalDate startDate;

    @NotNull(message = "종료일을 입력해주세요.")
    private LocalDate endDate;
}
