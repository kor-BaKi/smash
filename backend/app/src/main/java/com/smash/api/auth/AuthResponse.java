package com.smash.api.auth;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UserInfo user;

    @Getter
    @Builder
    public static class UserInfo {
        private Long id;
        private String name;
        private String role;
        private Long groupId; // 배정된 조 ID
    }
}
