package com.smash.domain.application;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ApplicationMemoRepository extends JpaRepository<ApplicationMemo, Long> {
    List<ApplicationMemo> findByApplicationOrderByCreatedAtAsc(Application application);

    void deleteById(Long id);
}
