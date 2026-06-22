package com.smash.api.auth;

import com.smash.auth.AuthResult;
import com.smash.domain.user.Role;

public record UserSummary(Long id, String name, Role role, Long groupId) {

    public static UserSummary from(AuthResult result) {
        return new UserSummary(result.userId(), result.name(), result.role(), result.groupId());
    }
}
