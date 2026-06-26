package com.smash.api.activity;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ActivityController {

    private final ActivityService activityService;

    // D-1. 오늘 내 활동 조회 (부원)
    @GetMapping("/api/v1/me/activities/today")
    public ResponseEntity<ApiResponse<List<ActivityResponse>>> getTodayActivities(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(activityService.getTodayActivities(userId)));
    }

    // D-2. 참여 응답 (이월 포함 통합)
    @PostMapping("/api/v1/me/activities/{activityId}/participation")
    public ResponseEntity<ApiResponse<Void>> participate(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long activityId,
            @RequestBody @Valid ParticipationRequest request
    ) {
        activityService.participate(activityId, userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // D-3. 이월 후보 조회
    @GetMapping("/api/v1/me/activities/{activityId}/carryover-candidates")
    public ResponseEntity<ApiResponse<List<CarryoverCandidateResponse>>> getCarryoverCandidates(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long activityId
    ) {
        return ResponseEntity.ok(ApiResponse.success(activityService.getCarryoverCandidates(userId, activityId)));
    }

    // D-4. 응답 취소
    @DeleteMapping("/api/v1/me/activities/{activityId}/participation")
    public ResponseEntity<ApiResponse<Void>> cancelParticipation(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long activityId
    ) {
        activityService.cancelParticipation(activityId, userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // D-5. 활동 상세 조회 (공통)
    @GetMapping("/api/v1/activities/{activityId}")
    public ResponseEntity<ApiResponse<ActivityDetailResponse>> getActivityDetail(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long activityId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                activityService.getActivityDetail(userId, activityId)
        ));
    }

    // D-6. 날짜별 활동 목록 (임원)
    @GetMapping("/api/v1/admin/activities")
    public ResponseEntity<ApiResponse<List<ActivitySummaryResponse>>> getActivitiesByDate(
            @RequestParam(required = false) String date
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                activityService.getActivitiesByDate(date)
        ));
    }

    // D-7. 활동 수동 제어 (임원)
    @PatchMapping("/api/v1/admin/activities/{activityId}")
    public ResponseEntity<ApiResponse<Void>> updateActivity(
            @PathVariable Long activityId,
            @RequestBody ActivityUpdateRequest request
    ) {
        activityService.updateActivity(activityId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
