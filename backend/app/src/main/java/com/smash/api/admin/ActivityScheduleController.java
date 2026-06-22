package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleSlot;
import com.smash.service.ActivityScheduleService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/activity-schedules")
@RequiredArgsConstructor
public class ActivityScheduleController {

    private final ActivityScheduleService activityScheduleService;

    @PutMapping
    public ApiResponse<List<ActivityScheduleResponse>> replaceAll(@Valid @RequestBody ActivitySchedulesRequest request) {
        List<ActivityScheduleSlot> slots = request.schedules().stream()
                .map(item -> new ActivityScheduleSlot(item.dayOfWeek(), item.timeSlot(), item.isActive()))
                .toList();
        List<ActivitySchedule> saved = activityScheduleService.replaceAll(slots);
        return ApiResponse.success(saved.stream().map(ActivityScheduleResponse::from).toList());
    }

    @GetMapping
    public ApiResponse<List<ActivityScheduleResponse>> getAll() {
        List<ActivitySchedule> schedules = activityScheduleService.getAll();
        return ApiResponse.success(schedules.stream().map(ActivityScheduleResponse::from).toList());
    }
}
