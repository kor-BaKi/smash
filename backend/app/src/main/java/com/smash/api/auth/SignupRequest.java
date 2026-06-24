package com.smash.api.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class SignupRequest {

    @NotBlank(message = "가입코드를 입력해주세요.")
    private String code;

    @NotBlank(message = "학번을 입력해주세요.")
    private String studentNo;

    @NotBlank(message = "비밀번호를 입력해주세요.")
    private String password;
}
