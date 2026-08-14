package com.smash.domain.application;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/*
    지원 폼 자체를 저장하는 테이블
    학기마다 새로운 폼을 만들 수 있음
 */

@Entity
@Table(name = "application_form")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ApplicationForm { // 설문 폼

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private boolean isActive; // 폼 활성화 상태

    @Column
    private LocalDateTime startDate;

    @Column
    private LocalDateTime endDate;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public ApplicationForm(boolean isActive, LocalDateTime startDate, LocalDateTime endDate) {
        this.isActive = isActive;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public void toggle(boolean isActive) { // 토글로 활성화 비활성화 가능
        this.isActive = isActive;
    }

    public void updatePeriod(LocalDateTime startDate, LocalDateTime endDate) { // 설문 기간 변경
        this.startDate = startDate;
        this.endDate = endDate;
    }
}
