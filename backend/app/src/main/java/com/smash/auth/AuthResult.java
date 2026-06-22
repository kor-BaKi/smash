package com.smash.auth;

import com.smash.domain.user.Role;

public record AuthResult(
        String accessToken,
        String refreshToken,
        Long userId,
        String name,
        Role role,
        Long groupId
) {
}
