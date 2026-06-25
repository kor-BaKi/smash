package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ActivityScheduleRepository extends JpaRepository<ActivitySchedule, Long> {

    Optional<ActivitySchedule> findByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);

    @Query("SELECT a FROM ActivitySchedule a ORDER BY CASE a.dayOfWeek " +
            "WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3 " +
            "WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 END, a.timeSlot ASC")
    List<ActivitySchedule> findAllOrderByDayOfWeek();
}
