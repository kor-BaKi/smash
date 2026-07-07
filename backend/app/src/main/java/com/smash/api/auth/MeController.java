package com.smash.api.auth;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class MeController {

    private final AuthService authService;

    @GetMapping("/api/v1/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> getMe(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(authService.getMe(userId)));
    }
}
