package com.smash.auth;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class LoginAttemptService {

    private static final int MAX_FAILURES = 5;
    private static final Duration LOCK_DURATION = Duration.ofMinutes(10);
    private static final Duration FAILURE_WINDOW = Duration.ofMinutes(10);
    private static final int PURGE_THRESHOLD = 10_000;

    // Attempt :  학번 하나의 상태(실패 횟수, 첫 실패 시각, 잠금 해제 시각)를 담는 작은 값 객체
    private record Attempt(int failures, Instant firstFailureAt, Instant lockedUntil) {
        boolean isLockedAt(Instant now) {
            return lockedUntil != null && now.isBefore(lockedUntil);
        }

        boolean isStaleAt(Instant now) {
            if (lockedUntil != null) return !now.isBefore(lockedUntil);
            return now.isAfter(firstFailureAt.plus(FAILURE_WINDOW));
        }
    }

    private final ConcurrentHashMap<String, Attempt> attempts = new ConcurrentHashMap<>();

    public boolean isLocked(String key) {
        Attempt attempt = attempts.get(key);
        return attempt != null && attempt.isLockedAt(Instant.now());
    }

    public void recordFailure(String key) {
        Instant now = Instant.now();
        if (attempts.size() > PURGE_THRESHOLD) {
            attempts.values().removeIf(a -> a.isStaleAt(now));
        }

        attempts.compute(key, (k, current) -> {
            if (current == null || current.isStaleAt(now)) {
                return new Attempt(1, now, null);
            }
            if (current.isLockedAt(now)) {
                return current;
            }
            int failures = current.failures() + 1;
            Instant lockedUntil = failures >= MAX_FAILURES ? now.plus(LOCK_DURATION) : null;
            return new Attempt(failures, current.firstFailureAt(), lockedUntil);
        });
    }

    public void recordSuccess(String key) {
        attempts.remove(key);
    }
}