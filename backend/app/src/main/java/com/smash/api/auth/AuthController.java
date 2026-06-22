package com.smash.api.auth;

import com.smash.auth.AuthService;
import com.smash.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ApiResponse<AuthResponse> signup(@Valid @RequestBody SignupRequest request) {
        var result = authService.signup(request.code(), request.studentNo(), request.password());
        return ApiResponse.success(AuthResponse.from(result));
    }

    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        var result = authService.login(request.studentNo(), request.password());
        return ApiResponse.success(AuthResponse.from(result));
    }

    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        var result = authService.refresh(request.refreshToken());
        return ApiResponse.success(TokenResponse.from(result));
    }

    // 사용자 식별은 JWT subject 고정 정책에 따라 SecurityContext에서만 추출한다 (IDOR 방지).
    @PostMapping("/logout")
    public ApiResponse<Void> logout(@AuthenticationPrincipal Long userId) {
        authService.logout(userId);
        return ApiResponse.success(null);
    }
}
