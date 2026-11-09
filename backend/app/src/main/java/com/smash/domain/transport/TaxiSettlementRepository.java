package com.smash.domain.transport;

import com.smash.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TaxiSettlementRepository extends JpaRepository<TaxiSettlement, Long> {
    Optional<TaxiSettlement> findByTransportGroup(TransportGroup transportGroup);
    void deleteByTransportGroup(TransportGroup transportGroup);

    List<TaxiSettlement> findByPayer(User payer);
}
