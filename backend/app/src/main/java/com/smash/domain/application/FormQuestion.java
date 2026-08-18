package com.smash.domain.application;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "form_question")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FormQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "form_id", nullable = false)
    private ApplicationForm form; // 어떤 폼의 질문인지 연결. 폼 하나에 여러 질문 (ManyToOne)

    @Column(nullable = false)
    private String content; // 질문 내용 -> ex. "지원 동기를 작성해주세요.", "자기소개를 해주세요." 등

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private QuestionType questionType; // 질문 타입

    @Column(nullable = false)
    private boolean isRequired; // 필수 여부 -> true : 미입력 시 제출 불가. false : 선택 사항

    @Column(nullable = false)
    private int orderIndex; // 질문 순서 -> orderIndex : 0 -> 첫 번째 질문, 1 -> 두 번째 질문 ...

    @Column
    private String options; // "있음,없음,모름"

    public void updateOptions(String options) {
        this.options = options;
    }

    @Builder
    public FormQuestion(ApplicationForm form, String content, QuestionType questionType, boolean isRequired, int orderIndex, String options) {
        this.form = form;
        this.content = content;
        this.questionType = questionType;
        this.isRequired = isRequired;
        this.orderIndex = orderIndex;
        this.options = options;
    }

    public void update(String content, boolean isRequired, int orderIndex) { // 질문 수정 메서드
        this.content = content;
        this.isRequired = isRequired;
        this.orderIndex = orderIndex;
    }
}
