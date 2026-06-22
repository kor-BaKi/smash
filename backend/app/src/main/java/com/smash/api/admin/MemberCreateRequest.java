package com.smash.api.admin;

import jakarta.validation.constraints.NotBlank;

public record MemberCreateRequest(
        @NotBlank(message = "이름은 필수입니다.") String name,
        @NotBlank(message = "학번은 필수입니다.") String studentNo,
        String department,
        String phone,
        @NotBlank(message = "기수는 필수입니다.") String joinTerm
) {
}
