package com.smash.domain.transport;

import com.smash.domain.activity.Activity;
import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "taxi_settlement")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class TaxiSettlement { // 결제자 테이블

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transport_goup_id", nullable = false) // 외래 키 컬럼 이름 지정
    private TransportGroup transportGroup; // // 어떤 호차의 정산인지 -> 1호차, 2호차 ...

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id", nullable = false)
    private Activity activity; // 어떤 활동의 정산인지 9/1일 화 1-3 활동 정산

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payer_id", nullable = false)
    private User payer;

    @Column(nullable = false)
    private int totalAmount;

    @Column(nullable = false)
    private int amountPerPerson;

    @Column
    private String accountBank; // 은행명

    @Column
    private String accountNumber; // 계좌번호

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public TaxiSettlement(TransportGroup transportGroup, Activity activity,
                          User payer, int totalAmount, int amountPerPerson,
                          String accountBank, String accountNumber) {
        this.transportGroup = transportGroup;
        this.activity = activity;
        this.payer = payer;
        this.totalAmount = totalAmount;
        this.amountPerPerson = amountPerPerson;
        this.accountBank = accountBank;
        this.accountNumber = accountNumber;
    }
}
