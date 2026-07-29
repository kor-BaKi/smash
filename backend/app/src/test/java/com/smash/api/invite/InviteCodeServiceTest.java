package com.smash.api.invite;

import com.smash.common.exception.BusinessException;
import com.smash.domain.invite.InviteCode;
import com.smash.domain.invite.InviteCodeRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InviteCodeServiceTest {

    @Mock
    private InviteCodeRepository inviteCodeRepository;

    @InjectMocks
    private InviteCodeService inviteCodeService;

    @Test
    @DisplayName("기존 코드가 없으면 새 가입코드를 생성한다")
    void createInviteCode_noneExists_createsNew() {
        // given
        when(inviteCodeRepository.findAll()).thenReturn(Collections.emptyList());
        when(inviteCodeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // when
        InviteCodeResponse result = inviteCodeService.createInviteCode();

        // then
        assertThat(result.getCode()).isNotNull();
        assertThat(result.getCode()).hasSize(8);
        verify(inviteCodeRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("기존 코드가 있으면 재발급하고 save를 호출하지 않는다")
    void createInviteCode_alreadyExists_regenerates() {
        // given
        InviteCode existing = InviteCode.builder().code("OLDCODE1").build();
        when(inviteCodeRepository.findAll()).thenReturn(List.of(existing));

        // when
        InviteCodeResponse result = inviteCodeService.createInviteCode();

        // then
        assertThat(result.getCode()).isNotEqualTo("OLDCODE1");
        assertThat(result.getCode()).hasSize(8);
        // 재발급은 기존 엔티티를 수정하므로 save() 호출 없음
        verify(inviteCodeRepository, never()).save(any());
    }

    @Test
    @DisplayName("존재하지 않는 코드를 토글하면 예외가 발생한다")
    void toggleInviteCode_notFound_throwsException() {
        // given
        when(inviteCodeRepository.findById(999L)).thenReturn(Optional.empty());

        InviteCodeToggleRequest request = new InviteCodeToggleRequest();
        request.setIsActive(true);

        // when & then
        assertThatThrownBy(() -> inviteCodeService.toggleInviteCode(999L, request))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("토글 요청 시 isActive 값이 Boolean 래퍼 타입으로 정상 전달된다")
    void toggleInviteCode_booleanWrapper_appliedCorrectly() {
        // given
        InviteCode inviteCode = InviteCode.builder().code("TESTCODE").build();
        // 초기 상태: isActive = true (빌더에서 기본값)

        when(inviteCodeRepository.findById(1L)).thenReturn(Optional.of(inviteCode));

        InviteCodeToggleRequest request = new InviteCodeToggleRequest();
        request.setIsActive(false); // 비활성화 요청

        // when
        inviteCodeService.toggleInviteCode(1L, request);

        // then
        assertThat(inviteCode.isActive()).isFalse();
    }

    @Test
    @DisplayName("가입코드 목록이 없으면 빈 리스트를 반환한다")
    void getInviteCodes_noneExists_returnsEmptyList() {
        // given
        when(inviteCodeRepository.findAll()).thenReturn(Collections.emptyList());

        // when
        var result = inviteCodeService.getInviteCodes();

        // then
        assertThat(result).isEmpty();
    }
}