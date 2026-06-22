package com.smash.domain.activity;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FreePeriodRepository extends JpaRepository<FreePeriod, Long> {

    List<FreePeriod> findByStartDateLessThanEqualAndEndDateGreaterThanEqual(LocalDate start, LocalDate end);
}
