package com.smash.domain.poll;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "poll_options")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PollOption {
    // 하나의 투표에 대한 옵션
    // ex. 하나의 투표 : 셔틀콕 공동 구매 수요 조사
    // ex. 옵션 : 1타, 2타, 3타, 4타 이상

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id", nullable = false)
    private Poll poll;

    @Column(nullable = false)
    private String content;

    @Column(nullable = false)
    private int orderIndex;

    @Builder
    public PollOption(Poll poll, String content, int orderIndex) {
        this.poll = poll;
        this.content = content;
        this.orderIndex = orderIndex;
    }
}
