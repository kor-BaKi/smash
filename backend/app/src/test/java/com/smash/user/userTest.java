package com.smash.user;

import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

public class userTest {

    private User activeMember() {
        User user = User.builder()
                .studentNo("20250001")
                .name("강감찬")
                .password("password")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .joinTerm("2026-09")
                .role(Role.ADMIN)
                .status(Status.ACTIVE)
                .build();
        ReflectionTestUtils.setField(user, "id", 7L);
        user.assignGroup(3L);
        return user;
    }

    @Test
    @DisplayName("탈퇴하면 개인정보가 지워지고 학번이 id 기반 값으로 바뀐다")
    void withdraw_clearsPersonalData() {
        User user = activeMember();

        user.withdraw();

        assertThat(user.getStudentNo()).isEqualTo("withdrawn-7");
        assertThat(user.getName()).isEqualTo("탈퇴한 회원");
        assertThat(user.getPassword()).isNull();
        assertThat(user.getDepartment()).isNull();
        assertThat(user.getPhone()).isNull();
        assertThat(user.getJoinTerm()).isNull();
        assertThat(user.getDeletedAt()).isNotNull();
    }

    @Test
    @DisplayName("탈퇴하면 조 소속과 임원 권한이 해제된다")
    void withdraw_releasesGroupAndRole() {
        User user = activeMember();

        user.withdraw();

        assertThat(user.getGroupId()).isNull();
        assertThat(user.getRole()).isEqualTo(Role.MEMBER);
    }

    @Test
    @DisplayName("탈퇴해도 상태는 ACTIVE로 유지되어 지원자 목록에 나타나지 않는다")
    void withdraw_keepsStatusActive() {
        User user = activeMember();

        user.withdraw();

        assertThat(user.getStatus()).isEqualTo(Status.ACTIVE);
    }
}
