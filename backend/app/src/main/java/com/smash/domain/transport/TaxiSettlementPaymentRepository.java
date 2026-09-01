package com.smash.domain.transport;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface TaxiSettlementPaymentRepository extends JpaRepository<TaxiSettlementPayment, Long> {
    List<TaxiSettlementPayment> findBySettlement(TaxiSettlement settlement);
    Optional<TaxiSettlementPayment> findBySettlementAndUser(
            TaxiSettlement settlement, com.smash.domain.user.User user);
    void deleteBySettlement(TaxiSettlement settlement);
}