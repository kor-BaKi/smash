package com.smash.api.admin;

import com.smash.domain.user.Status;
import com.smash.domain.user.User;

public record MemberCreateResponse(Long id, Status status) {

    public static MemberCreateResponse from(User user) {
        return new MemberCreateResponse(user.getId(), user.getStatus());
    }
}
