package com.smash.domain.poll;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "poll_votes",
        uniqueConstraints = @UniqueConstraint(columnNames = {"poll_id", "user_id"})) // 한 투표에 한 사람이 딱 한 번만 투표할 수 있음

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PollVote { // 각 옵션에 투표한 기록 여러 개

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id", nullable = false)
    private Poll poll; // 어떤 투표인지

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "option_id", nullable = false)
    private PollOption option; // 무엇을 골랐는지

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user; // 누가 골랐는지

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public PollVote(Poll poll, PollOption option, User user) {
        this.poll = poll;
        this.option = option;
        this.user = user;
    }
}
