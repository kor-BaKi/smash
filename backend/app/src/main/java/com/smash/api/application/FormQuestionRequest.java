package com.smash.api.application;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class FormQuestionRequest {

    @NotBlank(message = "질문 내용을 입력해주세요.")
    private String content;

    @NotNull(message = "질문 타입을 선택해주세요.")
    private String questionType;

    private boolean isRequired;

    private int orderIndex;

    private String options;
}
