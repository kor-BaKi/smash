package com.smash.api.auth;

import com.smash.auth.JwtProvider;
import com.smash.common.exception.BusinessException;
import com.smash.domain.invite.InviteCodeRepository;
import com.smash.domain.token.RefreshToken;
import com.smash.domain.token.RefreshTokenRepository;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final InviteCodeRepository inviteCodeRepository;
    private final RefreshTokenRepository refreshTokenRepository;

    @Transactional
    public AuthResponse signup(SignupRequest request) {

        inviteCodeRepository.findByCodeAndIsActiveTrue(request.getCode())
                .orElseThrow(() -> new BusinessException(
                        "INVALID_INVITE_CODE", "유효하지 않은 가입코드입니다."
                ));

        User user = userRepository.findByStudentNo(request.getStudentNo())
                .orElseThrow(() -> new BusinessException(
                        "STUDENT_NO_NOT_FOUND", "사전 등록된 학번이 없습니다."));

        if (user.getStatus() == Status.ACTIVE) {
            throw new BusinessException("ALREADY_REGISTERED", "이미 가입된 학번입니다.");
        }

        user.signup(passwordEncoder.encode(request.getPassword()));

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByStudentNo(request.getStudentNo())
                .orElseThrow(() -> new BusinessException(
                        "STUDENT_NO_NOT_FOUND", "학번 또는 비밀번호가 올바르지 않습니다."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BusinessException(
                    "INVALID_PASSWORD", "학번 또는 비밀번호가 올바르지 않습니다.");
        }

        if (user.getStatus() != Status.ACTIVE) {
            throw new BusinessException("NOT_ACTIVE", "가입이 완료되지 않은 계정입니다.");
        }

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtProvider.generateAccessToken(
                user.getId(), user.getRole().name());
        String refreshToken = jwtProvider.generateRefreshToken(user.getId());

        // Refresh Token 서버 저장 (있으면 교체, 없으면 새로 생성)
        LocalDateTime expiresAt = LocalDateTime.now()
                .plusSeconds(jwtProvider.getRefreshExpiration() / 1000);

        refreshTokenRepository.findByUserId(user.getId())
                .ifPresentOrElse(
                        existing -> existing.rotate(refreshToken, expiresAt),
                        () -> refreshTokenRepository.save(RefreshToken.builder()
                                .userId(user.getId()).token(refreshToken).expiresAt(expiresAt).build())
                );

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .user(AuthResponse.UserInfo.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .role(user.getRole().name())
                        .groupId(user.getGroupId())
                        .build())
                .build();
    }

    // 토큰 재발급
    @Transactional
    public AuthResponse refresh(String refreshToken) {
        // 서버에 저장된 토큰과 비교
        RefreshToken stored = refreshTokenRepository.findByToken(refreshToken)
                .orElseThrow(() -> new BusinessException(
                        "INVALID_REFRESH_TOKEN", "유효하지 않는 리프레시 토큰입니다."
                ));

        // JWT 유효성 검증
        if (!jwtProvider.isValid(refreshToken)) {
            refreshTokenRepository.delete(stored);
            throw new BusinessException("INVALID_REFRESH_TOKEN", "만료된 리프레시 토큰입니다.");
        }

        // 새 토큰 발급
        Long userId = jwtProvider.getUserId(refreshToken);
        User user = userRepository.findById(userId).orElseThrow(() -> new BusinessException(
                "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
        ));

        String newAccessToken = jwtProvider.generateAccessToken(
                user.getId(), user.getRole().name()
        );
        String newRefreshToken = jwtProvider.generateRefreshToken(user.getId());

        LocalDateTime expiresAt = LocalDateTime.now()
                .plusSeconds(jwtProvider.getRefreshExpiration() / 1000);

        // 기존 토큰 교체
        stored.rotate(newRefreshToken, expiresAt);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .user(AuthResponse.UserInfo.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .role(user.getRole().name())
                        .groupId(user.getGroupId())
                        .build())
                .build();
    }

    // 로그아웃
    @Transactional
    public void logout(Long userId) {
        refreshTokenRepository.deleteByUserId(userId);
    }
}