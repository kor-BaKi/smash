package com.smash.api.activity;

import com.smash.common.ApiResponse;
import com.smash.service.ActivityAdminService;
import com.smash.service.ActivityDetail;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

// D-5: 임원/부원 공통. 집계·명단만 공개하고 충족/미달 같은 평가성 데이터는 E 영역 전용.
@RestController
@RequiredArgsConstructor
public class ActivityDetailController {

    private final ActivityAdminService activityAdminService;

    @GetMapping("/api/v1/activities/{activityId}")
    public ApiResponse<ActivityDetailResponse> getDetail(@PathVariable Long activityId) {
        ActivityDetail detail = activityAdminService.getActivityDetail(activityId);
        return ApiResponse.success(ActivityDetailResponse.from(detail));
    }
}
