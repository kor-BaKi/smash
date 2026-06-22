package com.smash.domain.group;

import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupRepository extends JpaRepository<Group, Long> {

    boolean existsByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);
}
