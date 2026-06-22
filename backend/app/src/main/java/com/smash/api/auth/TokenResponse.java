package com.smash.api.auth;

import com.smash.auth.TokenResult;

public record TokenResponse(String accessToken, String refreshToken) {

    public static TokenResponse from(TokenResult result) {
        return new TokenResponse(result.accessToken(), result.refreshToken());
    }
}
