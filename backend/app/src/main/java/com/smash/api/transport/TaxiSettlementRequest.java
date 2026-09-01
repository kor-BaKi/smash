package com.smash.api.transport;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class TaxiSettlementRequest {

    @NotNull(message = "총 금액을 입력해주세요.")
    private Integer totalAmount;

    @NotNull(message = "은행명을 입력해주세요.")
    private String accountBank;

    @NotNull(message = "계좌번호를 입력해주세요.")
    private String accountNumber;
}
