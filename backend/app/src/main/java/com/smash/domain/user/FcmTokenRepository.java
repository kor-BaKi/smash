package com.smash.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {

    // 유저의 모든 토큰 조회 (여러 기기)
    List<FcmToken> findByUser(User user);

    // 토큰으로 조회 (중복 방지용)
    Optional<FcmToken> findByToken(String token);

    // 유저 ID로 모든 토큰 삭제 (로그아웃 시)
    void deleteByUser(User user);

    void deleteByUserAndToken(User user, String token);

    @Modifying
    @Transactional(propagation = Propagation.REQUIRES_NEW) // REQUIRES_NEW가 필요한 이유는 호출하는 스케줄러가 @Transactional(readOnly = true)라서, 같은 트랜잭션에 참여하면 삭제가 반영되지 않기 때문
    void deleteByToken(String token);
}
