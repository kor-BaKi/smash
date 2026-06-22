package com.smash.api.admin;

import com.smash.domain.invite.InviteCode;

public record InviteCodeResponse(Long id, String code, boolean isActive) {

    public static InviteCodeResponse from(InviteCode inviteCode) {
        return new InviteCodeResponse(inviteCode.getId(), inviteCode.getCode(), inviteCode.isActive());
    }
}
