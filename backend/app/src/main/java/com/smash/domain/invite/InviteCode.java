package com.smash.domain.invite;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
@Table(name = "invite_code")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class InviteCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private InviteCode(String code) {
        this.code = code;
        this.active = true;
    }

    // B-6: 코드 생성은 Service에서 중복 검사 후 결정. 엔티티는 생성 시 항상 활성 상태로 시작.
    public static InviteCode create(String code) {
        return InviteCode.builder().code(code).build();
    }

    public void updateActive(boolean active) {
        this.active = active;
    }
}
