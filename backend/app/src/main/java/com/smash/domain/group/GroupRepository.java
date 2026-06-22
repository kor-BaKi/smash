package com.smash.domain.group;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupRepository extends JpaRepository<Group, Long> {

    boolean existsByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);

    Optional<Group> findByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);
}
