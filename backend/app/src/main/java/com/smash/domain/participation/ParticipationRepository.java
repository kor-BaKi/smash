package com.smash.domain.participation;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ParticipationRepository extends JpaRepository<Participation, Long> {

    Optional<Participation> findByActivityIdAndUserId(Long activityId, Long userId);

    List<Participation> findByActivityId(Long activityId);

    List<Participation> findByUserIdAndActivityIdIn(Long userId, Collection<Long> activityIds);

    // hasCarryoverOut 판정용: 이 활동들을 이월 타깃으로 잡은 기록(생성 당시 activity_id는 다른 날일 수 있음).
    List<Participation> findByUserIdAndCarryoverTargetActivityIdIn(Long userId, Collection<Long> targetActivityIds);

    void deleteByActivityIdAndUserId(Long activityId, Long userId);

    // E-1: 충족 계산용. 어느 활동(날짜)에 달린 응답인지는 activityId로 다시 조회해서 월 범위와 대조한다.
    List<Participation> findByUserIdAndTypeIn(Long userId, Collection<ParticipationType> types);

    // E-3: 타조참 집계.
    List<Participation> findByActivityIdInAndType(Collection<Long> activityIds, ParticipationType type);
}
