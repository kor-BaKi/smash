package com.smash.api.admin;

import jakarta.validation.constraints.NotNull;

public record MemberGroupUpdateRequest(@NotNull Long groupId) {
}
