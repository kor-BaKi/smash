package com.smash.api.poll;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.poll.Poll;
import com.smash.domain.poll.PollOption;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Getter
@Builder
public class PollResponse {

    private Long id;
    private String title;
    private String description;
    private boolean isAnonymous;
    private boolean isClosed;
    private boolean isExpired;
    private LocalDateTime closedAt;
    private LocalDateTime createdAt;
    private List<OptionResult> options;
    private Long myVotedOptionId; // 내가 선택한 옵션 (null이면 미투표)

    @JsonProperty("isAnonymous")
    public boolean isAnonymous() {
        return isAnonymous;
    }

    @JsonProperty("isClosed")
    public boolean isClosed() {
        return isClosed;
    }

    @JsonProperty("isExpired")
    public boolean isExpired() {
        return isExpired;
    }

    @Getter
    @Builder
    public static class OptionResult {
        private Long id;
        private String content;
        private int orderIndex;
        private int voteCount;
        private List<String> voters; // 익면이면 빈 리스트
    }

    public static PollResponse of(Poll poll, List<PollOption> options, // 여러 곳에서 가져온 데이터를 하나의 응답 객체로 조립하는 역할
                                  Map<Long, Long> voteCounts,
                                  Map<Long, List<String>> voterNames,
                                  Long myVotedOptionId) {
        /*
        Poll             → 투표 제목, 마감 시각, 익명 여부 등 기본 정보
        List<PollOption> → 옵션 목록 ("속초", "강릉", "부산")
        Map<Long, Long> voteCounts   → 옵션별 투표 수
                               { 옵션id: 투표수 }
                               예: { 1L: 5, 2L: 3, 3L: 7 }
        Map<Long, List<String>> voterNames → 옵션별 투표자 이름 목록 (기명일 때)
                                      예: { 1L: ["김동현", "이서연"], 2L: ["박지훈"] }
        Long myVotedOptionId → 내가 선택한 옵션 id (미투표면 null)
         */
        return PollResponse.builder()
                .id(poll.getId())
                .title(poll.getTitle())
                .description(poll.getDescription())
                .isAnonymous(poll.isAnonymous())
                .isClosed(poll.isClosed())
                .isExpired(poll.isExpired())
                .closedAt(poll.getClosedAt())
                .createdAt(poll.getCreatedAt())
                .myVotedOptionId(myVotedOptionId)
                .options(options.stream()
                        .map(o -> OptionResult.builder()
                                .id(o.getId())
                                .content(o.getContent())
                                .orderIndex(o.getOrderIndex())
                                .voteCount(voteCounts.getOrDefault(o.getId(), 0L).intValue())
                                /*
                                getOrDefault(key, defaultValue)
                                → Map에서 key에 해당하는 값을 가져오되,
                                  없으면 defaultValue를 반환

                                즉: "이 옵션에 투표한 사람이 있으면 그 수를,
                                     아무도 안 투표했으면 0을 반환"

                                .intValue() → Long 타입을 int로 변환
                                              (voteCount 필드가 int라서)
                                -----------------------------------------------------------------
                                  ex.
                                  voteCounts = { 1L: 5, 2L: 3 }
                                    옵션 3번은 아무도 안 투표함

                                   옵션 1번: voteCounts.getOrDefault(1L, 0L) → 5
                                    옵션 2번: voteCounts.getOrDefault(2L, 0L) → 3
                                    옵션 3번: voteCounts.getOrDefault(3L, 0L) → 0 (없으니 기본값)
                                 */
                                .voters(voterNames.getOrDefault(o.getId(), List.of()))
                                .build())
                        .toList())
                .build();

    }
}

/*
           [전체 흐름 요약]
            Service가 각 테이블에서 데이터를 가져옴
              ↓
            PollResponse.of()에 전달
              ↓
            options.stream()으로 각 옵션을 순회하면서
              - 옵션 기본 정보 (id, content, orderIndex)
              - 이 옵션의 투표 수 (voteCounts에서 조회)
              - 이 옵션의 투표자 이름 (voterNames에서 조회)
            를 합쳐서 OptionResult를 만들고
              ↓
            최종 PollResponse 완성
 */