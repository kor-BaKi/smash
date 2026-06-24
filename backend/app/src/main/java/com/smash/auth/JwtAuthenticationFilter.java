package com.smash.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor // final 필드를 파라미터로 받는 생성자를 자동으로 만들어줌.
public class JwtAuthenticationFilter extends OncePerRequestFilter { // OncePerRequestFilter : 모든 HTTP 요청마다 딱 한번 실행되는 필터.

    private final JwtProvider jwtProvider;

//    HttpServletRequest request → 들어온 HTTP 요청 정보 (헤더, URL 등)
//    HttpServletResponse response → 나갈 HTTP 응답
//    FilterChain filterChain → 다음 필터로 넘겨주는 체인
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String token = extractToken(request);

        // 토큰 검증 후 인증 객체 생성
        if (StringUtils.hasText(token) && jwtProvider.isValid(token)) {
            Long userId = jwtProvider.getUserId(token);
            String role = jwtProvider.getRole(token);

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            userId,
                            null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + role))
                    );

            SecurityContextHolder.getContext().setAuthentication(authentication);
        }

        filterChain.doFilter(request, response);
    }

    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}