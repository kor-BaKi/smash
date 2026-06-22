package com.smash.api.member;

import com.smash.common.ApiResponse;
import com.smash.domain.group.Group;
import com.smash.service.AvailabilityService;
import com.smash.service.AvailabilityStatus;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me/availability")
@RequiredArgsConstructor
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    // 주체는 JWT subject로만 식별 (IDOR 방지). Body에 userId 없음.
    @PutMapping
    public ApiResponse<AvailabilitySubmitResponse> submit(
            @AuthenticationPrincipal Long userId, @Valid @RequestBody AvailabilitySubmitRequest request) {
        List<Group> groups = availabilityService.submitAvailability(userId, request.groupIds());
        return ApiResponse.success(new AvailabilitySubmitResponse(groups.stream().map(AvailabilityItem::from).toList()));
    }

    @GetMapping
    public ApiResponse<AvailabilityResponse> get(@AuthenticationPrincipal Long userId) {
        AvailabilityStatus status = availabilityService.getAvailability(userId);
        List<AvailabilityItem> items = status.groups().stream().map(AvailabilityItem::from).toList();
        return ApiResponse.success(new AvailabilityResponse(items, status.assigned(), status.assignedGroupId()));
    }
}
