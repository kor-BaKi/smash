package com.smash.api.auth;

import com.smash.auth.JwtProvider;
import com.smash.common.exception.BusinessException;
import com.smash.domain.invite.InviteCodeRepository;
import com.smash.domain.token.RefreshToken;
import com.smash.domain.token.RefreshTokenRepository;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtProvider jwtProvider;
    @Mock InviteCodeRepository inviteCodeRepository;
    @Mock RefreshTokenRepository refreshTokenRepository;

    @InjectMocks AuthService authService;

    private static final Long USER_ID = 1L;
    private static final String RAW_REFRESH = "raw-refresh-token";

    private User user;
    private LoginRequest loginRequest;

    @BeforeEach
    void setUp() {
        user = mock(User.class);
        given(user.getId()).willReturn(USER_ID);
        given(user.getName()).willReturn("김동현");
        given(user.getRole()).willReturn(Role.MEMBER);
        given(user.getStatus()).willReturn(Status.ACTIVE);
        given(user.getPassword()).willReturn("encoded-pw");
        given(userRepository.findByStudentNo("20200001")).willReturn(Optional.of(user));
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        loginRequest = mock(LoginRequest.class);
        given(loginRequest.getStudentNo()).willReturn("20200001");
        given(loginRequest.getPassword()).willReturn("pw");
        given(passwordEncoder.matches("pw", "encoded-pw")).willReturn(true);

        given(jwtProvider.generateAccessToken(anyLong(), anyString())).willReturn("access-token");
        given(jwtProvider.generateRefreshToken(USER_ID)).willReturn(RAW_REFRESH);
        given(jwtProvider.getRefreshExpiration()).willReturn(15_552_000_000L);
    }

    // 서비스와 같은 방식(SHA-256, hex)으로 기대값을 계산
    private static String sha256(String raw) {
        try {
            byte[] bytes = MessageDigest.getInstance("SHA-256")
                    .digest(raw.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    @DisplayName("재로그인: 기존 토큰 교체 시 평문이 아니라 해시가 저장된다")
    void login_existingToken_rotatesWithHash() {
        RefreshToken existing = mock(RefreshToken.class);
        given(refreshTokenRepository.findByUserId(USER_ID)).willReturn(Optional.of(existing));

        AuthResponse response = authService.login(loginRequest);

        ArgumentCaptor<String> saved = ArgumentCaptor.forClass(String.class);
        verify(existing).rotate(saved.capture(), any(LocalDateTime.class));
        assertThat(saved.getValue()).isNotEqualTo(RAW_REFRESH);
        assertThat(saved.getValue()).isEqualTo(sha256(RAW_REFRESH));
        assertThat(saved.getValue()).hasSize(64);
        // 클라이언트에게는 원문 토큰을 내려줌
        assertThat(response.getRefreshToken()).isEqualTo(RAW_REFRESH);
    }

    @Test
    @DisplayName("최초 로그인: 새로 저장하는 토큰도 해시로 저장된다")
    void login_firstTime_savesHash() {
        given(refreshTokenRepository.findByUserId(USER_ID)).willReturn(Optional.empty());

        authService.login(loginRequest);

        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getToken()).isEqualTo(sha256(RAW_REFRESH));
        assertThat(captor.getValue().getToken()).isNotEqualTo(RAW_REFRESH);
    }

    @Test
    @DisplayName("로그인: 비밀번호가 틀리면 INVALID_PASSWORD, 토큰은 저장되지 않음")
    void login_wrongPassword_rejected() {
        given(passwordEncoder.matches("pw", "encoded-pw")).willReturn(false);

        Throwable thrown = catchThrowable(() -> authService.login(loginRequest));

        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo("INVALID_PASSWORD");
        verify(refreshTokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("토큰 재발급: 해시로 조회하고 새 토큰도 해시로 교체한다")
    void refresh_lookupByHash_andRotateWithHash() {
        String oldRaw = "old-raw-refresh";
        String newRaw = "new-raw-refresh";
        RefreshToken stored = mock(RefreshToken.class);

        given(jwtProvider.isValid(oldRaw)).willReturn(true);
        given(jwtProvider.isRefreshToken(oldRaw)).willReturn(true);
        given(jwtProvider.getUserId(oldRaw)).willReturn(USER_ID);
        given(jwtProvider.generateRefreshToken(USER_ID)).willReturn(newRaw);
        given(refreshTokenRepository.findByToken(sha256(oldRaw))).willReturn(Optional.of(stored));

        AuthResponse response = authService.refresh(oldRaw);

        verify(stored).rotate(eq(sha256(newRaw)), any(LocalDateTime.class));
        assertThat(response.getRefreshToken()).isEqualTo(newRaw);
        // 평문으로는 조회하지 않아야 함
        verify(refreshTokenRepository, never()).findByToken(oldRaw);
    }

    @Test
    @DisplayName("토큰 재발급: DB에 평문이 저장된 토큰은 해시로 조회되지 않아 거부된다")
    void refresh_unknownHash_rejected() {
        String raw = "legacy-plaintext-token";
        given(jwtProvider.isValid(raw)).willReturn(true);
        given(jwtProvider.isRefreshToken(raw)).willReturn(true);
        given(refreshTokenRepository.findByToken(sha256(raw))).willReturn(Optional.empty());

        Throwable thrown = catchThrowable(() -> authService.refresh(raw));

        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo("INVALID_REFRESH_TOKEN");
    }
}