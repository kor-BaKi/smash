package com.smash.domain.schedule;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    @Query("SELECT s FROM Schedule s WHERE YEAR(s.date) = :year AND MONTH(s.date) = :month")
    List<Schedule> findByYearAndMonth(@Param("year") int year, @Param("month") int month);
}