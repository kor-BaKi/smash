
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

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;

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
                        () -> refreshTokenRepository.save(
                                RefreshToken.builder()
                                    .userId(user.getId())
                                    .token(hash(refreshToken)) // 해시로 저장
                                    .expiresAt(expiresAt)
                                    .build())
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

        if (!jwtProvider.isValid(refreshToken) || !jwtProvider.isRefreshToken(refreshToken)) {
            throw new BusinessException("INVALID_REFRESH_TOKEN", "유효하지 않는 리프레시 토큰입니다.");
        }

        // 서버에 저장된 토큰과 비교
        RefreshToken stored = refreshTokenRepository.findByToken(hash(refreshToken))
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
        stored.rotate(hash(newRefreshToken), expiresAt);

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

    @Transactional(readOnly = true)
    public AuthResponse.UserInfo getMe(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
                ));
        return AuthResponse.UserInfo.builder()
                .id(user.getId())
                .name(user.getName())
                .role(user.getRole().name())
                .groupId(user.getGroupId())
                .build();
    }

    // 비밀번호 변경
    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."
                ));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new BusinessException("INVALID_PASSWORD", "현재 비밀번호가 올바르지 않습니다.");
        }

        user.changePassword(passwordEncoder.encode(request.getNewPassword()));
    }

    private String hash(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256"); // MessageDigest : Java 표준 라이브러리의 해시 함수 클래스, getInstance("SHA-256"): SHA-256 알고리즘으로 초기화
            byte[] hashBytes = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashBytes);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 알고리즘을 찾을 수 없습니다.", e);
        }
    }
    /*
        SHA-256:
          어떤 길이의 입력이든 256비트(32바이트) 고정 길이 출력
          같은 입력 → 항상 같은 출력
          출력값으로 입력값 복원 불가 (단방향)
     */
}