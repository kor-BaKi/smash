package com.smash.api.admin;

import com.smash.domain.activity.FreePeriod;
import java.time.LocalDate;

public record FreePeriodResponse(Long id, String name, LocalDate startDate, LocalDate endDate) {

    public static FreePeriodResponse from(FreePeriod freePeriod) {
        return new FreePeriodResponse(
                freePeriod.getId(), freePeriod.getName(), freePeriod.getStartDate(), freePeriod.getEndDate());
    }
}
