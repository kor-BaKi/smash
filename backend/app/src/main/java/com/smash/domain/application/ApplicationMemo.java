package com.smash.domain.application;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "application_memo")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ApplicationMemo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "application_id", nullable = false)
    private Application application;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_id", nullable = false)
    private User admin;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected  void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public ApplicationMemo(Application application, User admin, String content) {
        this.application = application;
        this.admin = admin;
        this.content = content;
    }
}
