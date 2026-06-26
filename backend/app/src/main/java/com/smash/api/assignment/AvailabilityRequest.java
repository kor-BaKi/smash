package com.smash.api.assignment;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.List;

@Getter
public class AvailabilityRequest {

    @NotNull(message = "가능한 조를 선택해주세요.")
    private List<Long> groupIds;
}
