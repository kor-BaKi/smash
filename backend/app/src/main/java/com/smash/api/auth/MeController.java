package com.smash.api.auth;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class MeController {

    private final AuthService authService;
    private final WithdrawalService withdrawalService;

    @GetMapping("/api/v1/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> getMe(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(authService.getMe(userId)));
    }

    // 회원 탈퇴 (비밀번호 재확인 필요)
    @PostMapping("/api/v1/me/withdraw")
    public ResponseEntity<ApiResponse<Void>> withdraw(
            @AuthenticationPrincipal Long userId,
            @RequestBody @Valid WithdrawRequest request
    ) {
        withdrawalService.withdraw(userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
