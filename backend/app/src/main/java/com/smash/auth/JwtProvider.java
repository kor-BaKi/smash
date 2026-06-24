package com.smash.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtProvider { // 토큰을 만들고 검증

    private final SecretKey secretKey;
    private final long accessExpiration;
    private final long refreshExpiration;

    public JwtProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-expiration}") long accessExpiration,
            @Value("${jwt.refresh-expiration}") long refreshExpiration) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpiration = accessExpiration;
        this.refreshExpiration = refreshExpiration;
    }

    public String generateAccessToken(Long userId, String role) {
        return generateToken(userId, role, accessExpiration);
    }

    public String generateRefreshToken(Long userId) {
        return generateToken(userId, null, refreshExpiration);
    }

    private String generateToken(Long userId, String role, long expiration) {
        /*
        new Date() → 현재 시각
        now.getTime() → 현재 시각을 밀리초(ms)로 반환
        now.getTime() + expiration → 현재 시각 + 만료시간(ms) = 만료될 시각
        */
        Date now = new Date();
        Date expiredAt = new Date(now.getTime() + expiration);

        var builder = Jwts.builder()
                .subject(String.valueOf(userId))
                .issuedAt(now)              // 발급 시간
                .expiration(expiredAt)      // 만료 시간
                .signWith(secretKey);       // 서명 (위조 검증)

        if (role != null) {
            builder.claim("role", role);
        }

        return builder.compact();
    }

    public Claims getClaims(String token) { // 토큰을 검증하고 안에 담긴 데이터를 꺼내는 메서드
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getUserId(String token) {
        return Long.parseLong(getClaims(token).getSubject());
    }

    public String getRole(String token) {
        return getClaims(token).get("role", String.class);
    }

    public boolean isValid(String token) {
        try {
            getClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}