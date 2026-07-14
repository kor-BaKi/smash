package com.smash.api.schedule;

import com.smash.domain.activity.FreePeriod;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class FreePeriodResponse {

    private Long id;
    private LocalDate startDate;
    private LocalDate endDate;

    public static FreePeriodResponse of(FreePeriod freePeriod) {
        return FreePeriodResponse.builder()
                .id(freePeriod.getId())
                .startDate(freePeriod.getStartDate())
                .endDate(freePeriod.getEndDate())
                .build();
    }
}
