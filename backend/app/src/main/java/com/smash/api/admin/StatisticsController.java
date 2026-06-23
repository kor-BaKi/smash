package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.service.StatisticsService;
import java.time.YearMonth;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

// Phase 3 통계: 전부 임원 전용. /api/v1/admin/** 패턴으로 SecurityConfig가 이미 ROLE_ADMIN을 강제한다.
@RestController
@RequestMapping("/api/v1/admin/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping("/fulfillment-trend")
    public ApiResponse<List<FulfillmentTrendItem>> getFulfillmentTrend(
            @RequestParam(required = false) Long groupId,
            @RequestParam int fromYear, @RequestParam int fromMonth,
            @RequestParam int toYear, @RequestParam int toMonth) {
        var result = statisticsService.getFulfillmentTrend(
                groupId, YearMonth.of(fromYear, fromMonth), YearMonth.of(toYear, toMonth));
        return ApiResponse.success(result.stream().map(FulfillmentTrendItem::from).toList());
    }

    @GetMapping("/group-comparison")
    public ApiResponse<List<GroupComparisonResponseItem>> getGroupComparison(
            @RequestParam int year, @RequestParam int month) {
        var result = statisticsService.getGroupComparison(year, month);
        return ApiResponse.success(result.stream().map(GroupComparisonResponseItem::from).toList());
    }

    @GetMapping("/carryover-trend")
    public ApiResponse<List<CarryoverTrendItem>> getCarryoverTrend(
            @RequestParam int fromYear, @RequestParam int fromMonth,
            @RequestParam int toYear, @RequestParam int toMonth) {
        var result = statisticsService.getCarryoverTrend(YearMonth.of(fromYear, fromMonth), YearMonth.of(toYear, toMonth));
        return ApiResponse.success(result.stream().map(CarryoverTrendItem::from).toList());
    }
}
