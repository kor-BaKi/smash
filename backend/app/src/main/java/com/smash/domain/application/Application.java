package com.smash.domain.application;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "application")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Application { // 지원서

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "form_id", nullable = false)
    private ApplicationForm form; // 어떤 폼으로 지원했는지 연결

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String studentNo;

    @Column(nullable = false)
    private String department;

    @Column(nullable = false)
    private String phone;

    @Column(nullable = false)
    private String availabilities; // "MON:SLOT_13_15,THU:SLOT_15_17"

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private ApplicationStatus status; // 지원서 상태 : 미처리, 합격, 불합격

    @Column
    private String memo; // 메모 : ex. "면접 잘 봄.", "대회 급수 지역 A조" 등

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() { // 지원서가 처음 저장될 때 자동으로 실행
        this.createdAt = LocalDateTime.now(); // 현재 시각 자동 저장
        this.status = ApplicationStatus.PENDING; // PENDING으로 초기화
    }

    public void cancelReject() { this.status = ApplicationStatus.PENDING; }

    @Builder
    public Application(ApplicationForm form, String name, String studentNo, String department, String phone, String availabilities) {
        this.form = form;
        this.name = name;
        this.studentNo = studentNo;
        this.department = department;
        this.phone = phone;
        this.availabilities = availabilities;
    }

    public void accept() { this.status = ApplicationStatus.ACCEPTED; }
    public void reject() { this.status = ApplicationStatus.REJECTED; }
    public void updateMemo(String memo) { this.memo = memo; } // 메모 수정
}
