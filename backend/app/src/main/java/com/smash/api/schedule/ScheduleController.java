package com.smash.api.schedule;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ScheduleController {

    private final ScheduleService scheduleService;

    @PutMapping("/api/v1/amdin/activity-schedules")
    public ResponseEntity<ApiResponse<Void>> updateSchedules(
            @RequestBody @Valid ScheduleRequest request
    ) {
        scheduleService.updateSchedule(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/api/v1/admin/activity-schedules")
    public ResponseEntity<ApiResponse<List<ScheduleResponse>>> getSchedules() {
        return ResponseEntity.ok(ApiResponse.success(scheduleService.getSchedules()));
    }
}
