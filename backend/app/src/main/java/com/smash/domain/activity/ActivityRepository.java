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

    // E-3: 타조참은 어느 조에서나 발생할 수 있어 그룹 제한 없이 월 범위로 조회한다.
    List<Activity> findByActivityDateBetween(LocalDate start, LocalDate end);
}
