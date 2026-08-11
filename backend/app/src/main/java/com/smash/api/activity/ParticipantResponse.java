package com.smash.api.activity;

import com.smash.domain.participation.Participation;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ParticipantResponse {

    private Long userId;
    private String name;
    private String studentNo;
    private String participationType;   // 참여, 이월, 타조참
    private String travelType;       // Together, Alone, null

    public static ParticipantResponse of(Participation participation) {
        return ParticipantResponse.builder()
                .userId(participation.getUser().getId())
                .name(participation.getUser().getName())
                .studentNo(participation.getUser().getStudentNo())
                .participationType(participation.getType().name())
                .travelType(participation.getTravelType() == null
                        ? null
                        : participation.getTravelType().name())
                .build();

    }
}
