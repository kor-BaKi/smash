package com.smash.api.transport;

import com.smash.api.fcm.FcmService;
import com.smash.api.fcm.PushData;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.TaxiSettlement;
import com.smash.domain.transport.TaxiSettlementPaymentRepository;
import com.smash.domain.transport.TaxiSettlementRepository;
import com.smash.domain.transport.TransportGroup;
import com.smash.domain.transport.TransportGroupRepository;
import com.smash.domain.transport.TransportMember;
import com.smash.domain.transport.TransportMemberRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.AdditionalAnswers.returnsFirstArg;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

// 정산 요청 알림 문구: "6,500원을 김결제님께 송금해 주세요."
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TaxiSettlementNotificationTest {

    @Mock TaxiSettlementRepository settlementRepository;
    @Mock TaxiSettlementPaymentRepository paymentRepository;
    @Mock TransportGroupRepository transportGroupRepository;
    @Mock TransportMemberRepository transportMemberRepository;
    @Mock ActivityRepository activityRepository;
    @Mock UserRepository userRepository;
    @Mock FcmService fcmService;

    @InjectMocks TaxiSettlementService settlementService;

    private static final Long PAYER_ID = 1L;
    private static final Long RIDER_ID = 2L;
    private static final Long ACTIVITY_ID = 5L; // 활동 id와 호차 id를 다르게 해야 서로 바뀌는 실수를 잡는다
    private static final Long GROUP_ID = 3L;
    private static final String TITLE = "택시비 정산 요청";

    private final Locale originalLocale = Locale.getDefault();

    @BeforeEach
    void setUp() {
        TransportGroup group = mock(TransportGroup.class);
        User payer = user(PAYER_ID, "김결제");
        User rider = user(RIDER_ID, "이동승");
        TransportMember payerMember = member(payer);
        TransportMember riderMember = member(rider);

        given(transportGroupRepository.findById(GROUP_ID)).willReturn(Optional.of(group));
        given(activityRepository.findById(ACTIVITY_ID)).willReturn(Optional.of(mock(Activity.class)));
        given(userRepository.findById(PAYER_ID)).willReturn(Optional.of(payer));
        given(transportMemberRepository.existsByTransportGroupAndUserId(group, PAYER_ID)).willReturn(true);
        given(settlementRepository.findByTransportGroup(group)).willReturn(Optional.empty());
        given(transportMemberRepository.findByTransportGroup(group))
                .willReturn(List.of(payerMember, riderMember)); // 탑승 2명
        given(settlementRepository.save(any(TaxiSettlement.class))).willAnswer(returnsFirstArg());
    }

    @AfterEach
    void restoreLocale() {
        Locale.setDefault(originalLocale);
    }

    private User user(Long id, String name) {
        User u = mock(User.class);
        given(u.getId()).willReturn(id);
        given(u.getName()).willReturn(name);
        return u;
    }

    private TransportMember member(User user) {
        TransportMember m = mock(TransportMember.class);
        given(m.getUser()).willReturn(user);
        return m;
    }

    private TaxiSettlementRequest request(int totalAmount, boolean sendNotification) {
        TaxiSettlementRequest r = mock(TaxiSettlementRequest.class);
        given(r.getTotalAmount()).willReturn(totalAmount);
        given(r.getAccountBank()).willReturn("국민은행");
        given(r.getAccountNumber()).willReturn("123-456-789");
        given(r.isSendNotification()).willReturn(sendNotification);
        return r;
    }

    @Test
    @DisplayName("알림 문구: 천 단위 구분과 띄어쓰기가 들어간다 (6,500원을 김결제님께 송금해 주세요.)")
    void notification_message_formatted() {
        settlementService.create(ACTIVITY_ID, GROUP_ID, request(13000, true), PAYER_ID);

        // 활동 id 5, 호차 id 3 이 data에 문자열로 담긴다
        verify(fcmService).sendSettlementNotification(
                RIDER_ID, TITLE, "6,500원을 김결제님께 송금해 주세요.", PushData.settlement(ACTIVITY_ID, GROUP_ID));
    }

    @Test
    @DisplayName("알림 문구: 결제자 본인에게는 보내지 않는다")
    void notification_notSentToPayer() {
        settlementService.create(ACTIVITY_ID, GROUP_ID, request(13000, true), PAYER_ID);

        verify(fcmService, never()).sendSettlementNotification(
                eq(PAYER_ID), anyString(), anyString(), anyMap());
    }

    @Test
    @DisplayName("알림 옵션이 꺼져 있으면 보내지 않는다")
    void notification_off_notSent() {
        settlementService.create(ACTIVITY_ID, GROUP_ID, request(13000, false), PAYER_ID);

        verify(fcmService, never()).sendSettlementNotification(
                anyLong(), anyString(), anyString(), anyMap());
    }

    @Test
    @DisplayName("금액 형식: 1,000 미만, 1,000 이상, 백만 단위")
    void message_amountBoundaries() {
        assertThat(TaxiSettlementService.settlementMessage(0, "김결제"))
                .isEqualTo("0원을 김결제님께 송금해 주세요.");
        assertThat(TaxiSettlementService.settlementMessage(999, "김결제"))
                .isEqualTo("999원을 김결제님께 송금해 주세요.");
        assertThat(TaxiSettlementService.settlementMessage(1000, "김결제"))
                .isEqualTo("1,000원을 김결제님께 송금해 주세요.");
        assertThat(TaxiSettlementService.settlementMessage(1234567, "김결제"))
                .isEqualTo("1,234,567원을 김결제님께 송금해 주세요.");
    }

    @Test
    @DisplayName("서버 기본 로케일이 독일어 등이어도 구분자는 항상 ','")
    void message_independentOfDefaultLocale() {
        Locale.setDefault(Locale.GERMANY); // 독일 로케일은 천 단위 구분자가 '.'
        assertThat(TaxiSettlementService.settlementMessage(6500, "김결제"))
                .isEqualTo("6,500원을 김결제님께 송금해 주세요.");

        Locale.setDefault(Locale.FRANCE);  // 프랑스 로케일은 공백 계열 구분자
        assertThat(TaxiSettlementService.settlementMessage(6500, "김결제"))
                .isEqualTo("6,500원을 김결제님께 송금해 주세요.");
    }
}
