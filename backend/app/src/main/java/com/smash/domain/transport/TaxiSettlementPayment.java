package com.smash.domain.transport;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "taxi_settlement_payment")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class TaxiSettlementPayment { // 납부자 테이블

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settlement_id", nullable = false)
    private TaxiSettlement settlement; // 어떤 정산의 납부 현황인지 연결

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private Boolean isPaid;

    @Column
    private LocalDateTime paidAt;

    @Builder
    public TaxiSettlementPayment(TaxiSettlement settlement, User user) {
        this.settlement = settlement;
        this.user = user;
        this.isPaid = false;
    }

    public void markAsPaid() { // 체크 기능
        this.isPaid = true;
        this.paidAt = LocalDateTime.now();
    }

    public void markAsUnpaid() { // 체크 기능
        this.isPaid = false;
        this.paidAt = null;
    }
}
