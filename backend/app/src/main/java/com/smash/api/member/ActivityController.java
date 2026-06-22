package com.smash.api.member;

import com.smash.common.ApiResponse;
import com.smash.service.ActivityTodayView;
import com.smash.service.CarryoverCandidate;
import com.smash.service.ParticipationResult;
import com.smash.service.ParticipationService;
import com.smash.service.Scope;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me/activities")
@RequiredArgsConstructor
public class ActivityController {

    private final ParticipationService participationService;

    @GetMapping("/today")
    public ApiResponse<List<TodayActivityItem>> getToday(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "MY") Scope scope) {
        List<ActivityTodayView> views = participationService.getTodayActivities(userId, scope);
        return ApiResponse.success(views.stream().map(TodayActivityItem::from).toList());
    }

    @PostMapping("/{activityId}/participation")
    public ApiResponse<ParticipationResponse> submit(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long activityId,
            @Valid @RequestBody ParticipationRequest request) {
        ParticipationResult result = participationService.submitParticipation(
                userId, activityId, ParticipationTypeMapper.toDomain(request.type()), request.targetActivityId());
        return ApiResponse.success(ParticipationResponse.from(result));
    }

    @GetMapping("/{activityId}/carryover-candidates")
    public ApiResponse<List<CarryoverCandidateItem>> getCarryoverCandidates(
            @AuthenticationPrincipal Long userId, @PathVariable Long activityId) {
        List<CarryoverCandidate> candidates = participationService.getCarryoverCandidates(userId, activityId);
        return ApiResponse.success(candidates.stream().map(CarryoverCandidateItem::from).toList());
    }

    @DeleteMapping("/{activityId}/participation")
    public ApiResponse<Void> delete(@AuthenticationPrincipal Long userId, @PathVariable Long activityId) {
        participationService.deleteParticipation(userId, activityId);
        return ApiResponse.success(null);
    }
}
