package com.smash.api.invite;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.invite.InviteCode;
import lombok.Builder;

@Builder
public class InviteCodeResponse {

    private Long id;
    private String code;
    private boolean isActive;

    public Long getId() { return id; }
    public String getCode() { return code; }

    @JsonProperty("isActive")
    public boolean isActive() { return isActive; }

    public static InviteCodeResponse of(InviteCode inviteCode) {
        return InviteCodeResponse.builder()
                .id(inviteCode.getId())
                .code(inviteCode.getCode())
                .isActive(inviteCode.isActive())
                .build();
    }
}