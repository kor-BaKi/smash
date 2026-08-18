package com.smash.api.application;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.application.ApplicationForm;
import com.smash.domain.application.FormQuestion;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.List;

@Builder
public class ApplicationFormResponse {
    private Long id;          // 폼 ID (나중에 질문 추가/삭제 시 사용)
    private boolean isActive; // 활성화 여부 (웹 폼 접근 가능 여부)
    private LocalDateTime startDate; // 지원 시작일
    private LocalDateTime endDate;   // 지원 마감일
    private List<QuestionResponse> questions; // 임원이 만든 질문 목록
    private String options;

    public Long getId() { return id; }
    public LocalDateTime getStartDate() { return startDate; }
    public LocalDateTime getEndDate() { return endDate; }
    public String getOptions() { return options; }
    public List<QuestionResponse> getQuestions() { return questions; }

    @JsonProperty("isActive")
    public boolean isActive() { return isActive; }

    @Builder
    public static class QuestionResponse {
        private Long id;           // 질문 ID (답변 제출 시 어떤 질문인지 식별)
        private String content;    // "지원 동기를 작성해주세요."
        private String questionType; // TEXT, MULTILINE, SELECT
        private boolean isRequired;  // [필수 여부] isRequired == true → 미입력 시 제출 불가
        private int orderIndex;    // 질문 순서 (0, 1, 2...)
        private String options; // 선택형

        public Long getId() { return id; }
        public String getContent() { return content; }
        public String getQuestionType() { return questionType; }
        public int getOrderIndex() { return orderIndex; }
        public String getOptions() { return options; }

        @JsonProperty("isRequired")
        public boolean isRequired() { return isRequired; }
    }

    public static ApplicationFormResponse of(
            ApplicationForm form, List<FormQuestion> questions
    ) {
        return ApplicationFormResponse.builder()
                .id(form.getId())
                .isActive(form.isActive())
                .startDate(form.getStartDate())
                .endDate(form.getEndDate())
                .questions(questions.stream()
                        .map(q -> QuestionResponse.builder()
                                .id(q.getId())
                                .content(q.getContent())
                                .questionType(q.getQuestionType().name())
                                .isRequired(q.isRequired())
                                .orderIndex(q.getOrderIndex())
                                .options(q.getOptions())
                                .build())
                        .toList())
                .build();
    }
}
