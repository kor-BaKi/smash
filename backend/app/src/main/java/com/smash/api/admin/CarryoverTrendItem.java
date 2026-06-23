package com.smash.api.admin;

import com.smash.service.MonthlyCarryoverCount;

public record CarryoverTrendItem(int year, int month, int count) {

    public static CarryoverTrendItem from(MonthlyCarryoverCount monthly) {
        return new CarryoverTrendItem(monthly.year(), monthly.month(), monthly.count());
    }
}
