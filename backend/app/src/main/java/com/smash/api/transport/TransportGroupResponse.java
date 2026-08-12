package com.smash.api.transport;

import com.smash.domain.transport.TransportGroup;
import com.smash.domain.transport.TransportMember;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class TransportGroupResponse {
    private Long groupId;
    private int groupNumber;
    private List<MemberInfo> members;

    @Getter
    @Builder
    private static class MemberInfo {
        private Long userId;
        private String name;
        private String travelType;
    }

    public static TransportGroupResponse of(
            TransportGroup group, List<TransportMember> members
    ) {
        return TransportGroupResponse.builder()
                .groupId(group.getId())
                .groupNumber(group.getGroupNumber())
                .members(members.stream()
                        .map(m -> MemberInfo.builder()
                                .userId(m.getUser().getId())
                                .name(m.getUser().getName())
                                .travelType(m.getUser().getId() != null
                                        ? null : null) // 나중에 채움
                                .build())
                        .toList())
                .build();
    }
}
