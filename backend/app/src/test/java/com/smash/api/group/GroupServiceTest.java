package com.smash.api.group;

import com.smash.common.exception.BusinessException;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.Role;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class GroupServiceTest {

    @Mock GroupRepository groupRepository;
    @Mock UserRepository userRepository;

    @InjectMocks GroupService groupService;

    private static final Long GROUP_ID = 1L;
    private static final Long LEADER_ID = 10L;
    private static final Long ADMIN_ID = 20L;
    private static final Long MEMBER_ID = 30L;

    private Group group;

    @BeforeEach
    void setUp() {
        group = Group.builder()
                .dayOfWeek(DayOfWeek.MON)
                .timeSlot(TimeSlot.SLOT_13_15)
                .build();
        group.assignLeader(LEADER_ID);
        given(groupRepository.findById(GROUP_ID)).willReturn(Optional.of(group));
    }

    // 주의: given(...) 안의 인자 위치에서 이 메서드를 호출하면 중첩 스터빙 오류가 나므로
    // 반드시 변수에 먼저 담은 뒤 사용할 것
    private User userWithRole(Role role) {
        User user = mock(User.class);
        given(user.getRole()).willReturn(role);
        return user;
    }

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    @Test
    @DisplayName("부조장 지정: 조장이 아닌 임원은 성공")
    void assignViceLeader_admin_success() {
        User admin = userWithRole(Role.ADMIN);
        given(userRepository.findById(ADMIN_ID)).willReturn(Optional.of(admin));

        groupService.assignViceLeader(GROUP_ID, ADMIN_ID);

        assertThat(group.getViceLeaderUserId()).isEqualTo(ADMIN_ID);
    }

    @Test
    @DisplayName("부조장 지정: 존재하지 않는 유저는 RESOURCE_NOT_FOUND")
    void assignViceLeader_userNotFound() {
        given(userRepository.findById(99999L)).willReturn(Optional.empty());

        Throwable thrown = catchThrowable(
                () -> groupService.assignViceLeader(GROUP_ID, 99999L));

        assertBusiness(thrown, "RESOURCE_NOT_FOUND");
        assertThat(group.getViceLeaderUserId()).isNull();
    }

    @Test
    @DisplayName("부조장 지정: 일반 부원은 INVALID_REQUEST")
    void assignViceLeader_member_rejected() {
        User member = userWithRole(Role.MEMBER);
        given(userRepository.findById(MEMBER_ID)).willReturn(Optional.of(member));

        Throwable thrown = catchThrowable(
                () -> groupService.assignViceLeader(GROUP_ID, MEMBER_ID));

        assertBusiness(thrown, "INVALID_REQUEST");
        assertThat(group.getViceLeaderUserId()).isNull();
    }

    @Test
    @DisplayName("부조장 지정: 조장은 부조장이 될 수 없음")
    void assignViceLeader_leader_rejected() {
        User leader = userWithRole(Role.ADMIN);
        given(userRepository.findById(LEADER_ID)).willReturn(Optional.of(leader));

        Throwable thrown = catchThrowable(
                () -> groupService.assignViceLeader(GROUP_ID, LEADER_ID));

        assertBusiness(thrown, "INVALID_REQUEST");
        assertThat(group.getViceLeaderUserId()).isNull();
    }
}