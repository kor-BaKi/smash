package com.smash.domain.activity;

import com.smash.domain.group.Group;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ActivityRepository extends JpaRepository<Activity, Long> {

    Optional<Activity> findByGroupAndActivityDate(Group group, LocalDate date);

    @EntityGraph(attributePaths = {"group"})
    List<Activity> findByActivityDate(LocalDate date);

    @Query("SELECT a FROM Activity a WHERE a.group.id = :groupId " +
            "AND a.activityDate BETWEEN :start AND :end " +
            "AND a.isCancelled = false " +
            "AND a.activityType = 'REGULAR'")
    List<Activity> findRegularActivitiesByGroupAndMonth(
            @Param("groupId") Long groupId,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);

    @Query("SELECT a FROM Activity a WHERE a.group.id = :groupId " +
            "AND a.activityDate BETWEEN :start AND :end " +
            "AND a.isCancelled = false")
    List<Activity> findActivitiesByGroupAndMonth(
            @Param("groupId") Long groupId,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);

    // 취소된 활동까지 포함 (캘린더 표시용). 취소를 제외하는 위 조회는 이월 후보 계산에 쓰이므로 그대로 둔다.
    @Query("SELECT a FROM Activity a WHERE a.group.id = :groupId " +
            "AND a.activityDate BETWEEN :start AND :end " +
            "ORDER BY a.activityDate ASC")
    List<Activity> findAllActivitiesByGroupAndMonth(
            @Param("groupId") Long groupId,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);
}