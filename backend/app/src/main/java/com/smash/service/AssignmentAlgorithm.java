package com.smash.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

// 04-핵심로직.md 엔진1 의사코드 그대로: 선택지 적은 부원부터, 인원 적은 조(동점 시 id순)에 배정.
// Spring/DB에 의존하지 않는 순수 로직이라 빠른 단위테스트가 가능하다.
public final class AssignmentAlgorithm {

    private AssignmentAlgorithm() {
    }

    public static AssignmentResult assign(List<MemberAvailabilityInput> members, List<Long> groupIds) {
        List<MemberAvailabilityInput> sorted = members.stream()
                .sorted(Comparator.comparingInt((MemberAvailabilityInput m) -> m.availableGroupIds().size())
                        .thenComparing(MemberAvailabilityInput::userId))
                .toList();

        Map<Long, Integer> groupCount = new HashMap<>();
        for (Long groupId : groupIds) {
            groupCount.put(groupId, 0);
        }

        List<Assignment> assignments = new ArrayList<>();
        List<Unassigned> unassigned = new ArrayList<>();

        for (MemberAvailabilityInput member : sorted) {
            if (member.availableGroupIds().isEmpty()) {
                unassigned.add(new Unassigned(member.userId(), UnassignedReason.NO_AVAILABILITY));
                continue;
            }

            Comparator<Long> byCountThenId = Comparator
                    .comparingInt((Long groupId) -> groupCount.getOrDefault(groupId, 0))
                    .thenComparing(Comparator.naturalOrder());
            Long target = member.availableGroupIds().stream().min(byCountThenId).orElseThrow();

            assignments.add(new Assignment(member.userId(), target));
            groupCount.merge(target, 1, Integer::sum);
        }

        return new AssignmentResult(assignments, unassigned, groupCount);
    }
}
