package com.smash.domain.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Group 엔티티가 아직 없어 순수 FK 컬럼으로만 보관. 배정 전에는 NULL.
    @Column(name = "group_id")
    private Long groupId;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "student_no", nullable = false, unique = true, length = 20)
    private String studentNo;

    // 사전등록(PENDING) 시점에는 NULL. 가입완료(signup) 시 BCrypt로 채워짐.
    @Column(length = 255)
    private String password;

    @Column(length = 50)
    private String department;

    @Column(length = 20)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Column(name = "is_leader", nullable = false)
    private boolean isLeader;

    @Column(name = "join_term", length = 20)
    private String joinTerm;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // ERD에는 없는 컬럼. Refresh Token Rotation 정책(단일기기 가정)을 위해
    // 사용자별 현재 유효한 refresh token 1개만 보관한다.
    @Column(name = "refresh_token", length = 255)
    private String refreshToken;

    @Builder
    private User(String name, String studentNo, String department, String phone,
                  Role role, String joinTerm, Status status) {
        this.name = name;
        this.studentNo = studentNo;
        this.department = department;
        this.phone = phone;
        this.role = role;
        this.isLeader = false;
        this.joinTerm = joinTerm;
        this.status = status;
    }

    // A-1: 임원이 합격자를 사전등록 → role=MEMBER, status=PENDING, password=NULL
    public static User createPending(String name, String studentNo, String department,
                                      String phone, String joinTerm) {
        return User.builder()
                .name(name)
                .studentNo(studentNo)
                .department(department)
                .phone(phone)
                .role(Role.MEMBER)
                .joinTerm(joinTerm)
                .status(Status.PENDING)
                .build();
    }

    // A-3: 가입코드+학번대조 통과 후 비밀번호 설정 → PENDING -> ACTIVE
    public void activate(String encodedPassword) {
        this.password = encodedPassword;
        this.status = Status.ACTIVE;
    }

    // 로그인/재발급 시 회전, 로그아웃 시 null로 폐기
    public void updateRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    // B-3: 조장 지정. 기존 조장 해제는 호출부(GroupService)가 이전 조장 User에 별도로 호출한다.
    public void assignAsLeader() {
        this.isLeader = true;
    }

    public void unassignLeader() {
        this.isLeader = false;
    }
}
