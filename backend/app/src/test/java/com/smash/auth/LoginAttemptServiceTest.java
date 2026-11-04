package com.smash.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

public class LoginAttemptServiceTest {

    private LoginAttemptService service;

    @BeforeEach
    void setUp() {
        service = new LoginAttemptService();
    }

    @Test
    @DisplayName("실패 4번까지는 잠기지 않는다")
    void notLockedBelowLimit() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("11111111");
        }

        assertThat(service.isLocked("11111111")).isFalse();
    }

    @Test
    @DisplayName("연속 5번 실패하면 잠긴다.")
    void lockedAtLimit() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("11111111");
        }

        assertThat(service.isLocked("11111111")).isTrue();
    }

    @Test
    @DisplayName("잠기면 이후 실패를 더 기록해도 계속 잠겨있다")
    void stayLockedAfterMoreFailures() {
        for (int i = 0; i < 8; i++) {
            service.recordFailure("11111111");
        }

        assertThat(service.isLocked("11111111")).isTrue();
    }

    @Test
    @DisplayName("성공하면 실패 횟수가 초기화되어 다시 5번이 필요하다.")
    void successResetsFailures() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("20240001");
        }

        service.recordSuccess("20240001");
        for (int i = 0; i < 4; i++) {
            service.recordFailure("20240001");
        }

        assertThat(service.isLocked("20240001")).isFalse();
    }

    @Test
    @DisplayName("다른 학번의 실패는 영향을 주지 않는다")
    void independentPerStudent() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("20240001");
        }

        assertThat(service.isLocked("20240001")).isTrue();
        assertThat(service.isLocked("20240002")).isFalse();
    }

    @Test
    @DisplayName("기록이 없는 학번은 잠겨 있지 않다")
    void unknownKeyIsNotLocked() {
        assertThat(service.isLocked("never-seen")).isFalse();
    }
}
