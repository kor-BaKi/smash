package com.smash.domain.poll;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "polls")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Poll { // 투표 하나

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column
    private String description;

    @Column(nullable = false)
    private boolean isAnonymous;

    @Column
    private LocalDateTime closedAt; // null이면 수동 종료

    @Column(nullable = false)
    private boolean isClosed = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public Poll(String title, String description, boolean isAnonymous,
                LocalDateTime closedAt, User createdBy) {
        this.title = title;
        this.description = description;
        this.isAnonymous = isAnonymous;
        this.closedAt = closedAt;
        this.createdBy = createdBy;
    }

    public void close() {
        this.isClosed = true;
    }

    public boolean isExpired() {
        return isClosed ||
                (closedAt != null && LocalDateTime.now().isAfter(closedAt));
    }
}