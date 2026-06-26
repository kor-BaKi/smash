package com.smash.domain.participation;

import com.smash.domain.activity.Activity;
import com.smash.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ParticipationRepository extends JpaRepository<Participation, Integer> {

    // 특정 활동에 특정 부원의 응답이 있는지 조회. 재응답(upsert) 처리할 때 사용
    // 있으면 -> 기존 걸 updateType()으로 수정
    // 없으면 -> 새로 Participaiton 생성
    Optional<Participation> findByActivityAndUser(Activity activity, User user);

    // 이월 기록에서 target이 특정 활동인 것 (hasCarryoverOut 헬퍼)
    // 이 활동을 carryoverTarget으로 가리키는 내 이월 기록이 있는가?
    /*
        6/9에서 6/12로 이월했다면
        → Participation { activity=6/9, carryoverTarget=6/12, type=CARRYOVER }
        6/12를 열었을 때
        → existsByUserAndCarryoverTarget(user, 6/12활동) = true
        → "이 날 자격이 빠진 날이다" → 버튼 [CARRYOVER, OTHER_GROUP]
    */
    boolean existsByUserAndCarryoverTarget(User user, Activity target);

    // 특정 활동에 REGULAR 참여했는지 (hasRegularAttend 헬퍼)
    // 이 활동에 특정 타입으로 참여했는가?
    /*
        6/5에 REGULAR 참여했다면
        → existsByUserAndActivityAndType(user, 6/5활동, REGULAR) = true
        → 이월 후보에서 제외 (이미 참여한 날은 메울 게 없음)
    */
    boolean existsByUserAndActivityAndType(User user, Activity activity, ParticipationType type);


    // 그 달 REGULAR + CARRYOVER 참여 수 (충족 계산)
    @Query("SELECT COUNT(p) FROM Participation p " +
            "WHERE p.user.id = :userId " +
            "AND p.activity.activityDate BETWEEN :start AND :end " +
            "AND p.type IN ('REGULAR', 'CARRYOVER')")
    int countFulfilledByUserAndMonth(
            @Param("userId") Long userId,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);


    // 그 달 타조참 목록 (출석 현황)
    @Query("SELECT p FROM Participation p " +
            "WHERE p.user.id = :userId " +
            "AND p.activity.activityDate BETWEEN :start AND :end " +
            "AND p.type = 'OTHER_GROUP'")
    List<Participation> findOtherGroupByUserAndMonth(
            @Param("userId") Long userId,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end);

    List<Participation> findByActivity(Activity activity);
}
