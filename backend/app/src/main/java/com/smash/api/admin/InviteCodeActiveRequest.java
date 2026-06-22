package com.smash.api.admin;

import jakarta.validation.constraints.NotNull;

public record InviteCodeActiveRequest(@NotNull Boolean isActive) {
}
