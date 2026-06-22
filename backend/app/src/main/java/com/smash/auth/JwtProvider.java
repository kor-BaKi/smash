package com.smash.auth;

import com.smash.domain.user.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

// 토큰 발급/파싱만 담당. 검증 실패 시 예외를 그대로 던지고, 호출부(Filter/AuthService)가
// 상황에 맞는 에러코드(예: INVALID_REFRESH_TOKEN)로 변환한다.
@Component
public class JwtProvider {

    private static final String CLAIM_ROLE = "role";
    private static final String CLAIM_TYPE = "type";

    private final SecretKey key;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-expiration}") long accessExpirationMs,
            @Value("${jwt.refresh-expiration}") long refreshExpirationMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    public String generateAccessToken(Long userId, Role role) {
        return buildToken(userId, accessExpirationMs, TokenType.ACCESS, role);
    }

    public String generateRefreshToken(Long userId) {
        return buildToken(userId, refreshExpirationMs, TokenType.REFRESH, null);
    }

    // 만료/위조/형식오류 시 io.jsonwebtoken.JwtException(또는 하위타입)을 던진다.
    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getUserId(Claims claims) {
        return Long.valueOf(claims.getSubject());
    }

    public Role getRole(Claims claims) {
        return Role.valueOf(claims.get(CLAIM_ROLE, String.class));
    }

    public TokenType getTokenType(Claims claims) {
        return TokenType.valueOf(claims.get(CLAIM_TYPE, String.class));
    }

    private String buildToken(Long userId, long expirationMs, TokenType type, Role role) {
        Instant now = Instant.now();
        var builder = Jwts.builder()
                .subject(String.valueOf(userId))
                .claim(CLAIM_TYPE, type.name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(expirationMs)));
        if (role != null) {
            builder.claim(CLAIM_ROLE, role.name());
        }
        return builder.signWith(key).compact();
    }
}
