package com.smash.api.admin;

import com.smash.api.auth.WithdrawalService;
import com.smash.common.exception.BusinessException;
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

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AdminMemberServiceTest {

    @Mock UserRepository userRepository;
    @Mock WithdrawalService withdrawalService;

    @InjectMocks AdminMemberService adminMemberService;

    private static final Long ADMIN_ID = 1L;
    private static final Long MEMBER_ID = 7L;

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    @Test
    @DisplayName("부원 삭제: 공용 삭제·익명화 로직으로 처리된다 (물리 삭제 아님)")
    void deleteMember_delegatesToErase() {
        User member = mock(User.class);
        given(userRepository.findById(MEMBER_ID)).willReturn(Optional.of(member));

        adminMemberService.deleteMember(MEMBER_ID, ADMIN_ID);

        verify(withdrawalService).eraseAccount(member);
        verify(userRepository, never()).delete(any());
    }

    @Test
    @DisplayName("부원 삭제: 임원이 자기 자신을 삭제하려 하면 INVALID_REQUEST")
    void deleteMember_self_rejected() {
        Throwable thrown = catchThrowable(
                () -> adminMemberService.deleteMember(ADMIN_ID, ADMIN_ID));

        assertBusiness(thrown, "INVALID_REQUEST");
        verify(withdrawalService, never()).eraseAccount(any());
    }

    @Test
    @DisplayName("부원 삭제: 존재하지 않는 사용자는 RESOURCE_NOT_FOUND")
    void deleteMember_notFound_rejected() {
        given(userRepository.findById(MEMBER_ID)).willReturn(Optional.empty());

        Throwable thrown = catchThrowable(
                () -> adminMemberService.deleteMember(MEMBER_ID, ADMIN_ID));

        assertBusiness(thrown, "RESOURCE_NOT_FOUND");
        verify(withdrawalService, never()).eraseAccount(any());
    }
}