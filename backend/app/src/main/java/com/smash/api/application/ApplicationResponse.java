package com.smash.api.application;

import com.smash.domain.application.Application;
import com.smash.domain.application.ApplicationAnswer;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class ApplicationResponse {
    private Long id;
    private String name;
    private String studentNo;
    private String department;
    private String phone;
    private String availabilities;
    private String status;
    private String memo;
    private LocalDateTime createdAt;
    private List<AnswerResponse> answers;

    @Builder
    @Getter
    public static class AnswerResponse {
        private Long questionId;
        private String questionContent;
        private String answers;
    }

    // 상세 조회용 (답변 포함)
    public static ApplicationResponse of(
            Application application, List<ApplicationAnswer> answers
    ) {
        return ApplicationResponse.builder()
                .id(application.getId())
                .name(application.getName())
                .studentNo(application.getStudentNo())
                .department(application.getDepartment())
                .phone(application.getPhone())
                .availabilities(application.getAvailabilities())
                .status(application.getStatus().name())
                .memo(application.getMemo())
                .createdAt(application.getCreatedAt())
                .answers(answers.stream()
                        .map(a -> AnswerResponse.builder()
                                .questionId(a.getQuestion().getId())
                                .questionContent(a.getQuestion().getContent())
                                .answers(a.getAnswer())
                                .build())
                        .toList())
                .build();
    }

    // 목록 조회용 (답변 X)
    public static ApplicationResponse ofSimple(Application application) {
        return ApplicationResponse.builder()
                .id(application.getId())
                .name(application.getName())
                .studentNo(application.getStudentNo())
                .department(application.getDepartment())
                .phone(application.getPhone())
                .availabilities(application.getAvailabilities())
                .status(application.getStatus().name())
                .memo(application.getMemo())
                .createdAt(application.getCreatedAt())
                .build();
    }

    /*

        목록 화면: 이름, 학번, 학과, 상태만 보임
           → 답변까지 다 가져오면 데이터가 너무 많음
           → ofSimple() 사용

        상세 화면: 모든 답변 내용까지 보임
           → of() 사용

     */

}
