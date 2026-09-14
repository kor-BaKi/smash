package com.smash.api.fcm;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/fcm")
public class FcmController {

    private final FcmService fcmService;

    // FCM 토큰 저장
    @PostMapping("/token")
    public ResponseEntity<ApiResponse<Void>> saveToken(
            @AuthenticationPrincipal Long userId,
            @RequestBody FcmTokenRequest request
    ) {
        fcmService.saveToken(userId, request.getToken(), request.getDeviceType());
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // FCM 토큰 삭제 (로그아웃 시)
    @DeleteMapping("/token")
    public ResponseEntity<ApiResponse<Void>> deleteToken(
            @AuthenticationPrincipal Long userId
    ) {
        fcmService.deleteToken(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
