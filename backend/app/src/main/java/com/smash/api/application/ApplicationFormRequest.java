package com.smash.api.application;

import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ApplicationFormRequest {
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private boolean copyQuestions; // 이전 폼 복사 true: 폼 질문 복사 false: 처음부터 폼 질문 생성
}
