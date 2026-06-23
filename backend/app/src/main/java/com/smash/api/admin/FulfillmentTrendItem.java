package com.smash.api.admin;

import com.smash.service.MonthlyFulfillment;

public record FulfillmentTrendItem(int year, int month, int guaranteed, int fulfilled, double fulfillmentRate) {

    public static FulfillmentTrendItem from(MonthlyFulfillment monthly) {
        return new FulfillmentTrendItem(
                monthly.year(), monthly.month(), monthly.guaranteed(), monthly.fulfilled(), monthly.fulfillmentRate());
    }
}
