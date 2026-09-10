package com.smash.api.schedule;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class CalendarEventController {

    private final CalendarEventService calendarEventService;

    // 월별 일정 조회
    @GetMapping("/api/v1/calendar")
    public ResponseEntity<ApiResponse<List<CalendarEventResponse>>> getEvents(
            @RequestParam int year,
            @RequestParam int month,
            ) {
        return ResponseEntity.ok(ApiResponse.success(
                calendarEventService.getEvents(year, month)
        ));
    }

    // 일정 생성 (ADMIN)
    @PostMapping("/api/v1/admin/calendar")
    public ResponseEntity<ApiResponse<CalendarEventResponse>> create(
            @RequestBody CalendarEventRequest request,
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                calendarEventService.create(request, userId)
        ));
    }

    // 일정 삭제 (ADMIN)
    @DeleteMapping("/api/v1/admin/calendar/{scheduleId}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long scheduleId
    ) {
        calendarEventService.delete(scheduleId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
