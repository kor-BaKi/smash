package com.smash.api.fcm;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/notification")
public class NotificationSettingController {

    private final NotificationSettingService notificationSettingService;

    // 알림 설정 조회
    @GetMapping("/setting")
    public ResponseEntity<ApiResponse<NotificationSettingResponse>> getSetting(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                notificationSettingService.getSetting(userId)
        ));
    }

    // 알림 설정 수정
    @PutMapping("/setting")
    public ResponseEntity<ApiResponse<NotificationSettingResponse>> updateSetting(
            @AuthenticationPrincipal Long userId,
            @RequestBody NotificationSettingRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                notificationSettingService.updateSetting(userId, request)
        ));
    }
}
