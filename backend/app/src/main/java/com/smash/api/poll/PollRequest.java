package com.smash.api.poll;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
public class PollRequest {

    @NotBlank(message = "제목을 입력해주세요.")
    private String title;

    private String description;

    private boolean isAnonymous;

    private LocalDateTime closedAt; // null이면 수동 종료

    @NotEmpty(message = "옵션을 최소 2개 이상 입력해주세요.")
    @Size(min = 2, message = "옵션을 최소 2개 이상 입력해주세요.")
    private List<String> options;
}

