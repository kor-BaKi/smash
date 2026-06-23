package com.smash.service;

public record MonthlyFulfillment(int year, int month, int guaranteed, int fulfilled, double fulfillmentRate) {
}
