package com.smash.domain.activity;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ActivityRepository extends JpaRepository<Activity, Long> {

    Optional<Activity> findByGroupIdAndActivityDate(Long groupId, LocalDate activityDate);

    boolean existsByGroupIdAndActivityDate(Long groupId, LocalDate activityDate);

    List<Activity> findByActivityDate(LocalDate activityDate);

    List<Activity> findByGroupIdAndActivityDateBetween(Long groupId, LocalDate start, LocalDate end);
}
