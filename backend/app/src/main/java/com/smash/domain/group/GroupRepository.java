package com.smash.domain.group;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface GroupRepository extends JpaRepository<Group, Long> {

    boolean existsAllByDayOfWeekAndTimeSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot);

    @Query("SELECT g FROM Group g ORDER BY CASE g.dayOfWeek " +
            "WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3 " +
            "WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 END, g.timeSlot ASC")
    List<Group> findAllOrderByDayOfWeek();
}
