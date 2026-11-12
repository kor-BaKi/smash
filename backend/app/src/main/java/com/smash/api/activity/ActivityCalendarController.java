package com.smash.api.activity;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class ActivityCalendarController {

    private final ActivityCalendarService activityCalendarService;

    // 월별 내 조 활동일 + 자유 활동 기간 (로그인한 모든 사용자)
    @GetMapping("/api/v1/me/activity-calendar")
    public ResponseEntity<ApiResponse<ActivityCalendarResponse>> getActivityCalendar(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                activityCalendarService.getCalendar(userId, year, month)));
    }
}
