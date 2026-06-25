package com.smash.api.invite;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class InviteCodeToggleRequest {

    @NotNull
    private boolean isActive;
}
