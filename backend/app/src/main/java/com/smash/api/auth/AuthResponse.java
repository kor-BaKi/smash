package com.smash.api.auth;

import com.smash.auth.AuthResult;

public record AuthResponse(String accessToken, String refreshToken, UserSummary user) {

    public static AuthResponse from(AuthResult result) {
        return new AuthResponse(result.accessToken(), result.refreshToken(), UserSummary.from(result));
    }
}
