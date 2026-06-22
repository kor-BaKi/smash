package com.smash.domain.user;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByStudentNo(String studentNo);

    boolean existsByStudentNo(String studentNo);
}
