package com.smash.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.smash.domain.user.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

class JwtProviderTest {

    private final JwtProvider jwtProvider = new JwtProvider(
            "test-jwt-secret-key-must-be-at-least-256-bits-long-for-hs256",
            1000 * 60 * 30,
            1000 * 60 * 60 * 24 * 14
    );

    @Test
    void accessToken은_subject와_role과_type을_담는다() {
        String token = jwtProvider.generateAccessToken(1L, Role.MEMBER);

        Claims claims = jwtProvider.parseClaims(token);

        assertThat(jwtProvider.getUserId(claims)).isEqualTo(1L);
        assertThat(jwtProvider.getRole(claims)).isEqualTo(Role.MEMBER);
        assertThat(jwtProvider.getTokenType(claims)).isEqualTo(TokenType.ACCESS);
    }

    @Test
    void refreshToken은_subject와_type만_담고_role은_없다() {
        String token = jwtProvider.generateRefreshToken(1L);

        Claims claims = jwtProvider.parseClaims(token);

        assertThat(jwtProvider.getUserId(claims)).isEqualTo(1L);
        assertThat(jwtProvider.getTokenType(claims)).isEqualTo(TokenType.REFRESH);
        assertThat(claims.get("role")).isNull();
    }

    @Test
    void 위조된_토큰은_파싱시_예외가_발생한다() {
        String token = jwtProvider.generateAccessToken(1L, Role.MEMBER);
        String tampered = token.substring(0, token.length() - 1) + (token.endsWith("a") ? "b" : "a");

        assertThatThrownBy(() -> jwtProvider.parseClaims(tampered))
                .isInstanceOf(JwtException.class);
    }
}
