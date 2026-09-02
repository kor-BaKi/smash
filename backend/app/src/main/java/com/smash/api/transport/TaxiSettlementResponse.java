package com.smash.api.transport;

import com.smash.domain.transport.TaxiSettlement;
import com.smash.domain.transport.TaxiSettlementPayment;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class TaxiSettlementResponse {
    private Long id;
    private String payerName;
    private int totalAmount;
    private int amountPerPerson;
    private String accountBank;
    private String accountNumber;
    private List<PaymentStatus> payments;

    @Getter
    @Builder
    public static class PaymentStatus {
        private Long userId;
        private String userName;
        private Boolean isPaid;
        private String paidAt;

        public static PaymentStatus of(TaxiSettlementPayment payment) {
            return PaymentStatus.builder()
                    .userId(payment.getUser().getId())
                    .userName(payment.getUser().getName())
                    .isPaid(payment.getIsPaid())
                    .paidAt(payment.getPaidAt() != null
                            ? payment.getPaidAt().toString().substring(0, 16)
                            : null)
                    .build();
        }
    }

    public static TaxiSettlementResponse of(
            TaxiSettlement settlement,
            List<TaxiSettlementPayment> payments) {
        return TaxiSettlementResponse.builder()
                .id(settlement.getId())
                .payerName(settlement.getPayer().getName())
                .totalAmount(settlement.getTotalAmount())
                .amountPerPerson(settlement.getAmountPerPerson())
                .accountBank(settlement.getAccountBank())
                .accountNumber(settlement.getAccountNumber())
                .payments(payments.stream()
                        .map(PaymentStatus::of)
                        .toList())
                .build();
    }
}