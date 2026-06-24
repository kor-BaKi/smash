package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ActivityScheduleRepository extends JpaRepository<ActivitySchedule, Long> {

    Optional<ActivitySchedule> findByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);

    List<ActivitySchedule> findAllByOrderByDayOfWeekAscTimeSlotAsc();
}
