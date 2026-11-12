package com.smash.domain.activity;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface FreePeriodRepository extends JpaRepository<FreePeriod, Long> {

    // 기간이 [start, end] 와 하루라도 겹치는 자유 활동 기간
    @Query("SELECT f FROM FreePeriod f " +
            "WHERE f.startDate <= :end AND f.endDate >= :start " +
            "ORDER BY f.startDate ASC")
    List<FreePeriod> findOverlapping(
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);
}
