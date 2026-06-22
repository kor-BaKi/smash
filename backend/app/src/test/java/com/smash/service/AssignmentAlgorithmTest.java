package com.smash.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class AssignmentAlgorithmTest {

    private static final List<Long> ALL_GROUPS = List.of(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L);

    @Test
    void TC1_전원_전체조_가능하면_각_조_편차는_1_이하다() {
        List<MemberAvailabilityInput> members = new ArrayList<>();
        for (long userId = 1; userId <= 23; userId++) {
            members.add(new MemberAvailabilityInput(userId, ALL_GROUPS));
        }

        AssignmentResult result = AssignmentAlgorithm.assign(members, ALL_GROUPS);

        assertThat(result.unassigned()).isEmpty();
        int max = result.groupDistribution().values().stream().max(Integer::compareTo).orElseThrow();
        int min = result.groupDistribution().values().stream().min(Integer::compareTo).orElseThrow();
        assertThat(max - min).isLessThanOrEqualTo(1);
    }

    @Test
    void TC2_선택지가_1개뿐이면_그_조에_배정된다() {
        List<MemberAvailabilityInput> members = List.of(new MemberAvailabilityInput(1L, List.of(5L)));

        AssignmentResult result = AssignmentAlgorithm.assign(members, ALL_GROUPS);

        assertThat(result.assignments()).containsExactly(new Assignment(1L, 5L));
    }

    @Test
    void TC3_가능요일_미제출이면_NO_AVAILABILITY로_미배정된다() {
        List<MemberAvailabilityInput> members = List.of(new MemberAvailabilityInput(1L, List.of()));

        AssignmentResult result = AssignmentAlgorithm.assign(members, ALL_GROUPS);

        assertThat(result.assignments()).isEmpty();
        assertThat(result.unassigned()).containsExactly(new Unassigned(1L, UnassignedReason.NO_AVAILABILITY));
    }

    @Test
    void TC4_동일입력을_두번_돌리면_결과가_같다_결정성() {
        List<MemberAvailabilityInput> members = List.of(
                new MemberAvailabilityInput(3L, List.of(1L, 2L)),
                new MemberAvailabilityInput(1L, ALL_GROUPS),
                new MemberAvailabilityInput(2L, List.of(1L)),
                new MemberAvailabilityInput(4L, List.of(1L, 2L))
        );

        AssignmentResult first = AssignmentAlgorithm.assign(members, ALL_GROUPS);
        AssignmentResult second = AssignmentAlgorithm.assign(members, ALL_GROUPS);

        assertThat(first.assignments()).isEqualTo(second.assignments());
        assertThat(first.unassigned()).isEqualTo(second.unassigned());
        assertThat(first.groupDistribution()).isEqualTo(second.groupDistribution());
    }

    @Test
    void TC5_253명을_10개조에_배정하면_최대_최소_편차는_2_이하다() {
        List<MemberAvailabilityInput> members = new ArrayList<>();
        for (long userId = 1; userId <= 253; userId++) {
            members.add(new MemberAvailabilityInput(userId, ALL_GROUPS));
        }

        AssignmentResult result = AssignmentAlgorithm.assign(members, ALL_GROUPS);

        assertThat(result.assignments()).hasSize(253);
        int max = result.groupDistribution().values().stream().max(Integer::compareTo).orElseThrow();
        int min = result.groupDistribution().values().stream().min(Integer::compareTo).orElseThrow();
        assertThat(max - min).isLessThanOrEqualTo(2);
    }
}
