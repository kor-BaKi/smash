package com.smash.api.activity;

import com.smash.domain.participation.ParticipationType;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class ParticipationRequest {

    @NotNull(message = "참여 유형을 선택해주세요.")
    private ParticipationType type;

    private Long targetActivityId; // 이월일때만 필요
}
