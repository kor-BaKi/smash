package com.smash.api.assignment;

import com.smash.domain.availability.MemberAvailability;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AssignmentServiceTest {

    @Mock MemberAvailabilityRepository availabilityRepository;
    @Mock UserRepository userRepository;
    @Mock GroupRepository groupRepository;

    @InjectMocks AssignmentService assignmentService;

    @Test
    @DisplayName("자동 배정 미리보기 - 미배정 부원 없을 때 빈 결과")
    void preview_noUnassignedMembers_returnsEmpty() {
        // given
        given(userRepository.findUnassignedMembers()).willReturn(List.of());
        given(groupRepository.findAll()).willReturn(List.of());

        // when
        AssignmentPreviewResponse response = assignmentService.preview();

        // then
        assertThat(response.getAssignments()).isEmpty();
        assertThat(response.getUnassigned()).isEmpty();
    }

    @Test
    @DisplayName("자동 배정 미리보기 - 가능 요일 없는 부원은 미배정")
    void preview_memberWithNoAvailability_goesToUnassigned() {
        // given
        User member = User.builder()
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .role(Role.MEMBER)
                .status(Status.ACTIVE)
                .build();

        Group group = mock(Group.class);
        given(group.getId()).willReturn(1L);
        given(group.getLabel()).willReturn("월 1-3시");

        given(userRepository.findUnassignedMembers()).willReturn(List.of(member));
        given(groupRepository.findAll()).willReturn(List.of(group));
        given(availabilityRepository.findByUser(member)).willReturn(List.of());

        // when
        AssignmentPreviewResponse response = assignmentService.preview();

        // then
        assertThat(response.getAssignments()).isEmpty();
        assertThat(response.getUnassigned()).hasSize(1);
        assertThat(response.getUnassigned().get(0).getName())
                .isEqualTo("김동현");
    }

    @Test
    @DisplayName("자동 배정 미리보기 - 가능 요일 있는 부원은 배정")
    void preview_memberWithAvailability_getsAssigned() {
        // given
        User member = User.builder()
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .role(Role.MEMBER)
                .status(Status.ACTIVE)
                .build();

        Group group = mock(Group.class);
        given(group.getId()).willReturn(1L);
        given(group.getLabel()).willReturn("월 1-3시");

        MemberAvailability availability = mock(MemberAvailability.class);
        given(availability.getGroup()).willReturn(group);

        given(userRepository.findUnassignedMembers()).willReturn(List.of(member));
        given(groupRepository.findAll()).willReturn(List.of(group));
        given(availabilityRepository.findByUser(member))
                .willReturn(List.of(availability));

        // when
        AssignmentPreviewResponse response = assignmentService.preview();

        // then
        assertThat(response.getAssignments()).hasSize(1);
        assertThat(response.getAssignments().get(0).getName())
                .isEqualTo("김동현");
        assertThat(response.getUnassigned()).isEmpty();
    }

    @Test
    @DisplayName("희망 요일 전체 초기화")
    void resetAllAvailability_success() {
        // when
        assignmentService.resetAllAvailability();

        // then
        verify(availabilityRepository, times(1)).deleteAll();
    }

    @Test
    @DisplayName("수동 조 배정 성공")
    void assignMember_success() {
        // given
        User member = mock(User.class);
        Group group = mock(Group.class);

        given(userRepository.findById(1L)).willReturn(Optional.of(member));
        given(groupRepository.findById(1L)).willReturn(Optional.of(group));

        // when
        assignmentService.assignMember(1L, 1L);

        // then
        verify(member, times(1)).assignGroup(1L);
    }
}