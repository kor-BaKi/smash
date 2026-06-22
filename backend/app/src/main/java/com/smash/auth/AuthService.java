package com.smash.auth;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.invite.InviteCode;
import com.smash.domain.invite.InviteCodeRepository;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final InviteCodeRepository inviteCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    @Transactional
    public AuthResult signup(String code, String studentNo, String password) {
        inviteCodeRepository.findByCode(code)
                .filter(InviteCode::isActive)
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_INVITE_CODE));

        User user = userRepository.findByStudentNo(studentNo)
                .orElseThrow(() -> new BusinessException(ErrorCode.STUDENT_NO_NOT_FOUND));
        if (user.getStatus() == Status.ACTIVE) {
            throw new BusinessException(ErrorCode.ALREADY_REGISTERED);
        }

        user.activate(passwordEncoder.encode(password));
        return issueTokens(user);
    }

    @Transactional
    public AuthResult login(String studentNo, String password) {
        User user = userRepository.findByStudentNo(studentNo)
                .filter(u -> u.getStatus() == Status.ACTIVE)
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_CREDENTIALS));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
        }

        return issueTokens(user);
    }

    @Transactional
    public TokenResult refresh(String refreshToken) {
        User user = verifyRefreshToken(refreshToken);
        AuthResult issued = issueTokens(user);
        return new TokenResult(issued.accessToken(), issued.refreshToken());
    }

    @Transactional
    public void logout(Long userId) {
        userRepository.findById(userId).ifPresent(user -> user.updateRefreshToken(null));
    }

    private User verifyRefreshToken(String refreshToken) {
        try {
            Claims claims = jwtProvider.parseClaims(refreshToken);
            if (jwtProvider.getTokenType(claims) != TokenType.REFRESH) {
                throw new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN);
            }

            User user = userRepository.findById(jwtProvider.getUserId(claims))
                    .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN));
            if (!refreshToken.equals(user.getRefreshToken())) {
                throw new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN);
            }
            return user;
        } catch (JwtException | IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.INVALID_REFRESH_TOKEN);
        }
    }

    private AuthResult issueTokens(User user) {
        String accessToken = jwtProvider.generateAccessToken(user.getId(), user.getRole());
        String refreshToken = jwtProvider.generateRefreshToken(user.getId());
        user.updateRefreshToken(refreshToken);
        return new AuthResult(accessToken, refreshToken, user.getId(), user.getName(), user.getRole(), user.getGroupId());
    }
}
