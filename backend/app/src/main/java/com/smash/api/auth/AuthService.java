package com.smash.api.auth;

import com.smash.auth.JwtProvider;
import com.smash.common.exception.BusinessException;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    @Transactional
    public AuthResponse signup(SignupRequest request) {
        User user = userRepository.findByStudentNo(request.getStudentNo())
                .orElseThrow(() -> new BusinessException(
                        "STUDENT_NO_NOT_FOUND", "사전 등록된 학번이 없습니다."));

        if (user.getStatus() == Status.ACTIVE) {
            throw new BusinessException("ALREADY_REGISTERED", "이미 가입된 학번입니다.");
        }

        user.signup(passwordEncoder.encode(request.getPassword()));

        return buildAuthResponse(user);
    }

    @Transactional(readOnly = true)
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
}