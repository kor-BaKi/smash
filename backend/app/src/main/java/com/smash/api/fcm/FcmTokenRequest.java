package com.smash.api.fcm;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class FcmTokenRequest {

    @NotBlank(message = "토큰을 입력해주세요.")
    private String token;

    @NotBlank(message = "기기 타입을 입력해주세요.")
    private String deviceType;
}
