package com.smash.domain.application;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "application_answer")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ApplicationAnswer {  // 답변

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "application_id", nullable = false)
    private Application application;
                                                            // 어떤 지원서의 어떤 질문에 대한 답변인지 연결
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id", nullable = false)
    private FormQuestion question;

    @Column(nullable = false, columnDefinition = "TEXT") // TEXT : 최대 65,535자 제한   VARCHAR : 최대 255자 제한
    private String answer; // 답변 내용

    @Builder
    public ApplicationAnswer(Application application, FormQuestion question, String answer) {
        this.application = application;
        this.question = question;
        this.answer = answer;
    }

}
