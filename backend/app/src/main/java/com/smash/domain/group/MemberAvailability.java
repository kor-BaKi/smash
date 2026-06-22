package com.smash.domain.group;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

// 배정 근거로 영구 보관(배정 확정 후에도 삭제하지 않음). User/Group과는 plain FK로만
// 연결한다 (User.groupId와 같은 컨벤션).
@Entity
@Table(name = "member_availability", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "group_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MemberAvailability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "group_id", nullable = false)
    private Long groupId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private MemberAvailability(Long userId, Long groupId) {
        this.userId = userId;
        this.groupId = groupId;
    }

    public static MemberAvailability create(Long userId, Long groupId) {
        return MemberAvailability.builder().userId(userId).groupId(groupId).build();
    }
}
