package com.smash.api.auth;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.List;

@Getter
public class MemberRegisterRequest {

    @NotNull(message = "이름을 입력해주세요.")
    private String name;

    @NotNull(message = "학번을 입력해주세요.")
    private String studentNo;

    private String department;
    private String phone;
    private String joinTerm;

    @Getter
    public static class BulkRequest {
        private List<MemberRegisterRequest> members;
    }
}
