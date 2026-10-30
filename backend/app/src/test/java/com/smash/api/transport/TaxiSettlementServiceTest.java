package com.smash.api.transport;

import com.smash.api.fcm.FcmService;
import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.*;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TaxiSettlementServiceTest {

    @Mock TaxiSettlementRepository settlementRepository;
    @Mock TaxiSettlementPaymentRepository paymentRepository;
    @Mock TransportGroupRepository transportGroupRepository;
    @Mock TransportMemberRepository transportMemberRepository;
    @Mock ActivityRepository activityRepository;
    @Mock UserRepository userRepository;
    @Mock FcmService fcmService;

    @InjectMocks TaxiSettlementService settlementService;

    private static final Long PAYER_ID = 1L;
    private static final Long OUTSIDER_ID = 99L;

    private TransportGroup group;
    private TaxiSettlement settlement;

    @BeforeEach
    void setUp() {
        group = mock(TransportGroup.class);
        given(transportGroupRepository.findById(1L)).willReturn(Optional.of(group));

        User payer = mock(User.class);
        given(payer.getId()).willReturn(PAYER_ID);

        settlement = mock(TaxiSettlement.class);
        given(settlement.getPayer()).willReturn(payer);
        given(settlementRepository.findById(10L)).willReturn(Optional.of(settlement));
    }

    private void assertForbidden(Throwable thrown) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo("FORBIDDEN");
    }

    @Test
    @DisplayName("정산 조회: 호차 멤버가 아니면 FORBIDDEN")
    void getSettlement_notMember_forbidden() {
        given(transportMemberRepository.existsByTransportGroupAndUserId(group, OUTSIDER_ID))
                .willReturn(false);

        Throwable thrown = catchThrowable(
                () -> settlementService.getSettlement(1L, 1L, OUTSIDER_ID));

        assertForbidden(thrown);
        // 권한 검사에서 막히므로 정산 데이터는 조회조차 하지 않아야 함
        verify(settlementRepository, never()).findByTransportGroup(any());
    }

    @Test
    @DisplayName("정산 생성: 호차 멤버가 아니면 FORBIDDEN")
    void create_notMember_forbidden() {
        given(activityRepository.findById(1L)).willReturn(Optional.of(mock(Activity.class)));
        given(userRepository.findById(OUTSIDER_ID)).willReturn(Optional.of(mock(User.class)));
        given(transportMemberRepository.existsByTransportGroupAndUserId(group, OUTSIDER_ID))
                .willReturn(false);

        Throwable thrown = catchThrowable(() -> settlementService.create(
                1L, 1L, mock(TaxiSettlementRequest.class), OUTSIDER_ID));

        assertForbidden(thrown);
        verify(settlementRepository, never()).save(any());
    }

    @Test
    @DisplayName("납부 확인: 결제자가 아니면 FORBIDDEN, 납부 상태는 바뀌지 않음")
    void togglePayment_notPayer_forbidden() {
        Throwable thrown = catchThrowable(
                () -> settlementService.togglePayment(10L, 2L, OUTSIDER_ID));

        assertForbidden(thrown);
        verify(paymentRepository, never()).findBySettlementAndUser(any(), any());
    }

    @Test
    @DisplayName("납부 확인: 결제자는 미납 -> 납부로 토글")
    void togglePayment_payer_marksPaid() {
        User member = mock(User.class);
        TaxiSettlementPayment payment = mock(TaxiSettlementPayment.class);
        given(userRepository.findById(2L)).willReturn(Optional.of(member));
        given(paymentRepository.findBySettlementAndUser(settlement, member))
                .willReturn(Optional.of(payment));
        given(payment.getIsPaid()).willReturn(false);

        settlementService.togglePayment(10L, 2L, PAYER_ID);

        verify(payment).markAsPaid();
        verify(payment, never()).markAsUnpaid();
    }

    @Test
    @DisplayName("정산 삭제: 결제자가 아니면 FORBIDDEN, 삭제는 실행되지 않음")
    void delete_notPayer_forbidden() {
        Throwable thrown = catchThrowable(
                () -> settlementService.delete(10L, OUTSIDER_ID));

        assertForbidden(thrown);
        verify(paymentRepository, never()).deleteBySettlement(any());
        verify(settlementRepository, never()).delete(any());
    }

    @Test
    @DisplayName("정산 삭제: 결제자는 납부 현황과 정산을 삭제")
    void delete_payer_success() {
        settlementService.delete(10L, PAYER_ID);

        verify(paymentRepository).deleteBySettlement(settlement);
        verify(settlementRepository).delete(settlement);
    }
}