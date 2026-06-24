package com.smash.domain.user;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true) // NOT NULL, 중복 불가
    private String studentNo;

    @Column(nullable = false)
    private String name;

    private String password;

    private String department;

    private String phone;

    private String joinTerm;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean isLeader = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    private LocalDateTime deletedAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist // DB에 처음 저장되기 직전에 자동으로 실행. createdAt을 현재 시각으로 채워주는 용도
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public User(String studentNo, String name, String password,
                String department, String phone, String joinTerm,
                Role role, Status status) {
        this.studentNo = studentNo;
        this.name = name;
        this.password = password;
        this.department = department;
        this.phone = phone;
        this.joinTerm = joinTerm;
        this.role = role;
        this.status = status;
    }
}