package com.smash.domain.application;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ApplicationFormRepository extends JpaRepository<ApplicationForm, Long> {
    Optional<ApplicationForm> findTopByOrderByCreatedAtDesc(); // 가장 최근 폼 1개 조회 (현재 활성 폼)
}
