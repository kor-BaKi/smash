package com.smash.api.auth;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class RefreshRequest {

    @NotNull
    private String refreshToken;
}
