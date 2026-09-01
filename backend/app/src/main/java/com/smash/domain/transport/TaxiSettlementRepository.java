package com.smash.domain.transport;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TaxiSettlementRepository extends JpaRepository<TaxiSettlement, Long> {
    Optional<TaxiSettlement> findByTransportGroup(TransportGroup transportGroup);
    void deleteByTransportGroup(TransportGroup transportGroup);
}
