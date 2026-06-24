package com.smash.api.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class SignupRequest {

    @NotBlank(message = "가입코드를 입력해주세요.")
    private String code;

    @NotBlank(message = "학번을 입력해주세요.")
    private String studentNo; // String으로 받는 이유 : 학번이 0으로 시작할 수 있기 때문에

    @NotBlank(message = "비밀번호를 입력해주세요.")
    private String password; // 문자, 숫자 특수문자가 혼합되기 때문에 문자열
}
