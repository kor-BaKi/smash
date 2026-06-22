package com.smash.api.auth;

import jakarta.validation.constraints.NotBlank;

public record SignupRequest(
        @NotBlank(message = "가입코드는 필수입니다.") String code,
        @NotBlank(message = "학번은 필수입니다.") String studentNo,
        @NotBlank(message = "비밀번호는 필수입니다.") String password
) {
}
