package com.smash.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {

    // 유저의 모든 토큰 조회 (여러 기기)
    List<FcmToken> findByUser(User user);

    // 토큰으로 조회 (중복 방지용)
    Optional<FcmToken> findByToken(String token);

    // 유저 ID로 모든 토큰 삭제 (로그아웃 시)
    void deleteByUser(User user);
}
