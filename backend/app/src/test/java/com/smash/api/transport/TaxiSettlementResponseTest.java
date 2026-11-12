package com.smash.api.transport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smash.api.fcm.FcmService;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.TaxiSettlement;
import com.smash.domain.transport.TaxiSettlementPayment;
import com.smash.domain.transport.TaxiSettlementPaymentRepository;
import com.smash.domain.transport.TaxiSettlementRepository;
import com.smash.domain.transport.TransportGroup;
import com.smash.domain.transport.TransportGroupRepository;
import com.smash.domain.transport.TransportMember;
import com.smash.domain.transport.TransportMemberRepository;
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

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.AdditionalAnswers.returnsFirstArg;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;

// 정산 응답에 payerUserId 가 포함되는지, 기존 JSON 키는 그대로인지 확인한다
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TaxiSettlementResponseTest {

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

    private TransportGroup group;
    private Activity activity;
    private User payer;
    private User rider;
    private TaxiSettlementPayment riderPayment;

    @BeforeEach
    void setUp() {
        group = mock(TransportGroup.class);
        activity = mock(Activity.class);
        payer = user(PAYER_ID, "김결제");
        rider = user(RIDER_ID, "이동승");

        given(transportGroupRepository.findById(1L)).willReturn(Optional.of(group));
        given(activityRepository.findById(1L)).willReturn(Optional.of(activity));
        given(userRepository.findById(PAYER_ID)).willReturn(Optional.of(payer));
        given(transportMemberRepository.existsByTransportGroupAndUserId(group, PAYER_ID)).willReturn(true);
        given(transportMemberRepository.existsByTransportGroupAndUserId(group, RIDER_ID)).willReturn(true);
        // 주의: given(...) 인자 안에서 목을 만들면 중첩 스터빙 오류가 나므로 먼저 변수에 담는다
        TransportMember payerMember = member(payer);
        TransportMember riderMember = member(rider);
        given(transportMemberRepository.findByTransportGroup(group))
                .willReturn(List.of(payerMember, riderMember));
        given(settlementRepository.save(any(TaxiSettlement.class))).willAnswer(returnsFirstArg());
        given(paymentRepository.save(any(TaxiSettlementPayment.class))).willAnswer(returnsFirstArg());
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

    private TaxiSettlement settlement(User payerUser, String bank, String number) {
        return TaxiSettlement.builder()
                .transportGroup(group)
                .activity(activity)
                .payer(payerUser)
                .totalAmount(13000)
                .amountPerPerson(6500)
                .accountBank(bank)
                .accountNumber(number)
                .build();
    }

    private void givenExistingSettlement(TaxiSettlement settlement) {
        riderPayment = TaxiSettlementPayment.builder().settlement(settlement).user(rider).build();
        given(settlementRepository.findByTransportGroup(group)).willReturn(Optional.of(settlement));
        given(paymentRepository.findBySettlement(settlement)).willReturn(List.of(riderPayment));
    }

    private TaxiSettlementRequest createRequest() {
        TaxiSettlementRequest r = mock(TaxiSettlementRequest.class);
        given(r.getTotalAmount()).willReturn(13000);
        given(r.getAccountBank()).willReturn("국민은행");
        given(r.getAccountNumber()).willReturn("123-456-789");
        given(r.isSendNotification()).willReturn(false);
        return r;
    }

    private JsonNode json(TaxiSettlementResponse response) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readTree(mapper.writeValueAsString(response));
    }

    @Test
    @DisplayName("정산 생성 응답에 결제자 id가 포함된다")
    void create_responseHasPayerUserId() {
        given(settlementRepository.findByTransportGroup(group)).willReturn(Optional.empty());
        given(paymentRepository.findBySettlement(any(TaxiSettlement.class)))
                .willAnswer(invocation -> List.of(
                        TaxiSettlementPayment.builder()
                                .settlement(invocation.getArgument(0)).user(rider).build()));

        TaxiSettlementResponse res = settlementService.create(1L, 1L, createRequest(), PAYER_ID);

        assertThat(res.getPayerUserId()).isEqualTo(PAYER_ID);
        assertThat(res.getPayerName()).isEqualTo("김결제");
        assertThat(res.getAmountPerPerson()).isEqualTo(6500);
        assertThat(res.getPayments()).hasSize(1);
        assertThat(res.getPayments().get(0).getUserId()).isEqualTo(RIDER_ID);
    }

    @Test
    @DisplayName("정산 조회 응답에 결제자 id가 포함되고, 결제자는 납부 현황 목록에 없다")
    void getSettlement_responseHasPayerUserId() {
        givenExistingSettlement(settlement(payer, "국민은행", "123-456-789"));

        TaxiSettlementResponse res = settlementService.getSettlement(1L, 1L, RIDER_ID);

        assertThat(res.getPayerUserId()).isEqualTo(PAYER_ID);
        assertThat(res.getPayments()).extracting(TaxiSettlementResponse.PaymentStatus::getUserId)
                .containsExactly(RIDER_ID)
                .doesNotContain(PAYER_ID);
    }

    @Test
    @DisplayName("결제자가 탈퇴해도(이름 익명화, 계좌 \"-\") 결제자 id는 그대로 내려간다")
    void getSettlement_withdrawnPayer_idKept() {
        User withdrawn = user(PAYER_ID, "탈퇴한 회원");
        TaxiSettlement settlement = settlement(withdrawn, "국민은행", "123-456-789");
        settlement.clearAccount();
        givenExistingSettlement(settlement);

        TaxiSettlementResponse res = settlementService.getSettlement(1L, 1L, RIDER_ID);

        assertThat(res.getPayerUserId()).isEqualTo(PAYER_ID);
        assertThat(res.getPayerName()).isEqualTo("탈퇴한 회원");
        assertThat(res.getAccountBank()).isEqualTo("-");
        assertThat(res.getAccountNumber()).isEqualTo("-");
    }

    @Test
    @DisplayName("JSON: payerUserId 키가 추가되고 기존 키는 모두 그대로다")
    void json_addsPayerUserId_keepsExistingKeys() throws Exception {
        givenExistingSettlement(settlement(payer, "국민은행", "123-456-789"));

        JsonNode root = json(settlementService.getSettlement(1L, 1L, RIDER_ID));

        assertThat(root.fieldNames()).toIterable().containsExactlyInAnyOrder(
                "id", "payerName", "payerUserId", "totalAmount", "amountPerPerson",
                "accountBank", "accountNumber", "payments");
        assertThat(root.get("payerUserId").asLong()).isEqualTo(PAYER_ID);
        assertThat(root.get("payerName").asText()).isEqualTo("김결제");
        assertThat(root.get("totalAmount").asInt()).isEqualTo(13000);
        assertThat(root.get("amountPerPerson").asInt()).isEqualTo(6500);

        JsonNode payment = root.get("payments").get(0);
        assertThat(payment.fieldNames()).toIterable()
                .containsExactlyInAnyOrder("userId", "userName", "isPaid", "paidAt");
        assertThat(payment.get("isPaid").asBoolean()).isFalse();
    }
}
