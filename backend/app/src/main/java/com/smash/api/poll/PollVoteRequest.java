package com.smash.api.poll;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class PollVoteRequest {

    @NotNull(message = "옵션을 선택해주세요.")
    private Long optionId;
}
