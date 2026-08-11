package com.smash.api.activity;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class TravelTypeRequest {

    @NotNull(message = "이동 방법을 선택해주세요.")
    private String travelType;
}
