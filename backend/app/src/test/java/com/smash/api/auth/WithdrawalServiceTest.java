package com.smash.api.auth;

import com.smash.auth.LoginAttemptService;
import com.smash.common.exception.BusinessException;
import com.smash.domain.application.Application;
import com.smash.domain.application.ApplicationAnswerRepository;
import com.smash.domain.application.ApplicationMemoRepository;
import com.smash.domain.application.ApplicationRepository;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.token.RefreshTokenRepository;
import com.smash.domain.user.FcmTokenRepository;
import com.smash.domain.user.MemberNoteRepository;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserNotificationSettingRepository;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WithdrawalServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock LoginAttemptService loginAttemptService;
    @Mock RefreshTokenRepository refreshTokenRepository;
    @Mock FcmTokenRepository fcmTokenRepository;
    @Mock UserNotificationSettingRepository notificationSettingRepository;
    @Mock MemberAvailabilityRepository availabilityRepository;
    @Mock MemberNoteRepository memberNoteRepository;
    @Mock GroupRepository groupRepository;
    @Mock ApplicationRepository applicationRepository;
    @Mock ApplicationAnswerRepository applicationAnswerRepository;
    @Mock ApplicationMemoRepository applicationMemoRepository;

    @InjectMocks WithdrawalService withdrawalService;

    private static final Long USER_ID = 7L;
    private static final String STUDENT_NO = "20240001";

    private User user;
    private WithdrawRequest request;

    private User newUser(Long id, String studentNo, Role role) {
        User u = User.builder()
                .studentNo(studentNo)
                .name("김동현")
                .password("encoded-password")
                .department("컴퓨터공학과")
                .phone("010-1234-5678")
                .role(role)
                .status(Status.ACTIVE)
                .build();
        ReflectionTestUtils.setField(u, "id", id);
        return u;
    }

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    @BeforeEach
    void setUp() {
        user = newUser(USER_ID, STUDENT_NO, Role.MEMBER);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        request = mock(WithdrawRequest.class);
        given(request.getPassword()).willReturn("my-password");
        given(passwordEncoder.matches("my-password", "encoded-password")).willReturn(true);
    }

    @Test
    @DisplayName("비밀번호가 틀리면 INVALID_PASSWORD, 실패가 기록되고 아무것도 삭제되지 않는다")
    void wrongPassword_rejected_nothingDeleted() {
        given(passwordEncoder.matches("my-password", "encoded-password")).willReturn(false);

        Throwable thrown = catchThrowable(() -> withdrawalService.withdraw(USER_ID, request));

        assertBusiness(thrown, "INVALID_PASSWORD");
        verify(loginAttemptService).recordFailure(STUDENT_NO);
        verify(refreshTokenRepository, never()).deleteByUserId(anyLong());
        assertThat(user.getDeletedAt()).isNull();
        assertThat(user.getName()).isEqualTo("김동현");
    }

    @Test
    @DisplayName("시도 횟수 제한에 걸린 계정은 비밀번호를 검사하지 않고 TOO_MANY_ATTEMPTS")
    void lockedAccount_rejectedBeforePasswordCheck() {
        given(loginAttemptService.isLocked(STUDENT_NO)).willReturn(true);

        Throwable thrown = catchThrowable(() -> withdrawalService.withdraw(USER_ID, request));

        assertBusiness(thrown, "TOO_MANY_ATTEMPTS");
        verify(passwordEncoder, never()).matches(any(), any());
        assertThat(user.getDeletedAt()).isNull();
    }

    @Test
    @DisplayName("이미 탈퇴한 계정은 RESOURCE_NOT_FOUND")
    void alreadyWithdrawn_rejected() {
        user.withdraw();

        Throwable thrown = catchThrowable(() -> withdrawalService.withdraw(USER_ID, request));

        assertBusiness(thrown, "RESOURCE_NOT_FOUND");
    }

    @Test
    @DisplayName("마지막 남은 임원은 탈퇴할 수 없다 (INVALID_REQUEST)")
    void lastAdmin_rejected() {
        User admin = newUser(USER_ID, STUDENT_NO, Role.ADMIN);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(admin));
        given(userRepository.findAllActiveMembers()).willReturn(List.of(admin));

        Throwable thrown = catchThrowable(() -> withdrawalService.withdraw(USER_ID, request));

        assertBusiness(thrown, "INVALID_REQUEST");
        verify(refreshTokenRepository, never()).deleteByUserId(anyLong());
        assertThat(admin.getDeletedAt()).isNull();
    }

    @Test
    @DisplayName("정상 탈퇴: 로그인·알림·가용시간·메모가 삭제되고 계정이 익명화된다")
    void withdraw_deletesPersonalDataAndAnonymizes() {
        withdrawalService.withdraw(USER_ID, request);

        verify(loginAttemptService).recordSuccess(STUDENT_NO);
        verify(refreshTokenRepository).deleteByUserId(USER_ID);
        verify(fcmTokenRepository).deleteByUser(user);
        verify(availabilityRepository).deleteByUser(user);
        verify(memberNoteRepository).deleteByMember(user);
        verify(memberNoteRepository).deleteByAdmin(user);

        assertThat(user.getName()).isEqualTo("탈퇴한 회원");
        assertThat(user.getStudentNo()).isEqualTo("withdrawn-7");
        assertThat(user.getPassword()).isNull();
        assertThat(user.getDeletedAt()).isNotNull();
    }

    @Test
    @DisplayName("다른 임원이 있으면 임원도 탈퇴할 수 있고 조장·부조장 자리가 비워진다")
    void admin_withAnotherAdmin_canWithdraw_andLeavesLeaderSeats() {
        User admin = newUser(USER_ID, STUDENT_NO, Role.ADMIN);
        User otherAdmin = newUser(8L, "20240002", Role.ADMIN);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(admin));
        given(userRepository.findAllActiveMembers()).willReturn(List.of(admin, otherAdmin));

        Group leaderGroup = mock(Group.class);
        Group viceGroup = mock(Group.class);
        given(groupRepository.findByLeaderUserId(USER_ID)).willReturn(List.of(leaderGroup));
        given(groupRepository.findByViceLeaderUserId(USER_ID)).willReturn(List.of(viceGroup));

        withdrawalService.withdraw(USER_ID, request);

        verify(leaderGroup).assignLeader(null);
        verify(viceGroup).assignViceLeader(null);
        assertThat(admin.getRole()).isEqualTo(Role.MEMBER);
        assertThat(admin.getDeletedAt()).isNotNull();
    }

    @Test
    @DisplayName("지원서는 원래 학번으로 찾아 답변·메모를 지우고 익명화한다")
    void withdraw_scrubsApplicationFoundByOriginalStudentNo() {
        Application application = mock(Application.class);
        given(applicationRepository.findByStudentNo(STUDENT_NO)).willReturn(List.of(application));

        withdrawalService.withdraw(USER_ID, request);

        verify(applicationAnswerRepository).deleteByApplication(application);
        verify(applicationMemoRepository).deleteByApplication(application);
        verify(application).anonymize();
    }
}