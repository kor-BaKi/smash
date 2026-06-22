package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.service.ActivityAdminService;
import com.smash.service.ActivitySummaryView;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/activities")
@RequiredArgsConstructor
public class ActivityAdminController {

    private final ActivityAdminService activityAdminService;

    @GetMapping
    public ApiResponse<List<ActivitySummaryItem>> getByDate(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate target = (date != null) ? date : LocalDate.now();
        List<ActivitySummaryView> views = activityAdminService.getActivitiesByDate(target);
        return ApiResponse.success(views.stream().map(ActivitySummaryItem::from).toList());
    }

    @PatchMapping("/{activityId}")
    public ApiResponse<Void> update(@PathVariable Long activityId, @RequestBody ActivityUpdateRequest request) {
        activityAdminService.updateActivity(activityId, request.isCancelled(), request.activityType());
        return ApiResponse.success(null);
    }
}
