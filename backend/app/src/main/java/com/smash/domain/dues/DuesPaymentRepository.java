package com.smash.domain.dues;

import com.smash.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DuesPaymentRepository extends JpaRepository<DuesPayment, Long> {
    Optional<DuesPayment> findByUser(User user);

    boolean existsByUser(User user);

    void deleteByUser(User user);
}
