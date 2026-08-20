package com.smash.api.dues;

import com.smash.common.exception.BusinessException;
import com.smash.domain.dues.DuesPayment;
import com.smash.domain.dues.DuesPaymentRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.quality.Strictness;
import org.mockito.junit.jupiter.MockitoSettings;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DuesServiceTest {

    @Mock DuesPaymentRepository duesPaymentRepository;
    @Mock UserRepository userRepository;

    @InjectMocks DuesService duesService;

    @Test
    @DisplayName("회비 납부 처리 성공")
    void pay_success() {
        // given
        User user = mock(User.class);
        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(duesPaymentRepository.findByUser(user)).willReturn(Optional.empty());

        // when
        duesService.pay(1L);

        // then
        verify(duesPaymentRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("이미 납부한 경우 예외 발생")
    void pay_alreadyPaid_throwsException() {
        // given
        User user = mock(User.class);
        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(duesPaymentRepository.existsByUser(user)).willReturn(true);

        // when & then
        assertThatThrownBy(() -> duesService.pay(1L))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("이미 납부 처리된 부원입니다.");
    }

    @Test
    @DisplayName("회비 납부 취소 성공")
    void cancel_success() {
        // given
        User user = mock(User.class);
        given(userRepository.findById(1L)).willReturn(Optional.of(user));
        given(duesPaymentRepository.existsByUser(user)).willReturn(true);

        // when
        duesService.cancel(1L);

        // then
        verify(duesPaymentRepository, times(1)).deleteByUser(user);
    }

    @Test
    @DisplayName("회비 전체 초기화 성공")
    void reset_success() {
        // when
        duesService.reset();

        // then
        verify(duesPaymentRepository, times(1)).deleteAll();
    }
}