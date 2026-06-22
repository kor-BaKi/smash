package com.smash.domain.user;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByStudentNo(String studentNo);

    boolean existsByStudentNo(String studentNo);

    long countByGroupId(Long groupId);

    // 조 배정 엔진은 부원 전용. 임원 계정도 group_id가 NULL이라 role 조건이 없으면
    // "미배정자"에 같이 잡힌다.
    List<User> findByGroupIdIsNullAndStatusAndRole(Status status, Role role);

    // E-1: 충족 현황 조회 대상 (해당 조 소속 + 활성 부원).
    List<User> findByGroupIdAndStatusAndRole(Long groupId, Status status, Role role);

    // C-4 정합성 3중 체크 중 하나: WHERE group_id IS NULL 조건부 UPDATE로 동시성 보호.
    // 영향행수 0 = 그 사이 이미 배정됨 (skip 판정용).
    @Modifying
    @Query("UPDATE User u SET u.groupId = :groupId WHERE u.id = :userId AND u.groupId IS NULL")
    int assignGroupIfUnassigned(@Param("userId") Long userId, @Param("groupId") Long groupId);
}
