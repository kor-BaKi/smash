package com.smash.api.invite;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class InviteCodeToggleRequest {

    @NotNull
    private boolean isActive;
}