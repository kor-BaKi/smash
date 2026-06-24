package com.smash.domain.group;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GroupRepository extends JpaRepository<Group, Long> {

    boolean existsAllByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);

    List<Group> findAllByOrderByDayOfWeekAscTimeSlot();
}
