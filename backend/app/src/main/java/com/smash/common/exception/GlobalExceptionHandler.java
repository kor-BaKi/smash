package com.smash.common.exception;

import com.smash.common.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(BusinessException e) {
        HttpStatus status = resolveHttpStatus(e.getCode());
        log.warn("[BusinessException] code={}, message={}", e.getCode(), e.getMessage());
        return ResponseEntity
                .status(status)
                .body(ApiResponse.fail(e.getCode(), e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult()
                .getFieldErrors()
                .getFirst()
                .getDefaultMessage();
        log.warn("[ValidationException] message={}", message);
        return ResponseEntity
                .badRequest()
                .body(ApiResponse.fail("INVALID_INPUT", message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception e) {
        log.error("[UnhandledException] {}", e.getMessage(), e);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail("SERVER_ERROR", "서버 오류가 발생했습니다."));
    }

    private HttpStatus resolveHttpStatus(String code) {
        return switch (code) {
            // 404 — 리소스를 찾을 수 없음
            case "RESOURCE_NOT_FOUND" -> HttpStatus.NOT_FOUND;

            // 409 — 충돌 (이미 존재하거나 상태 불일치)
            case "OVERLAPPING_PERIOD",
                 "ALREADY_EXISTS",
                 "ALREADY_REGISTERED",
                 "ALREADY_ASSIGNED",
                 "ASSIGNMENT_CONFLICT"    -> HttpStatus.CONFLICT;

            // 401 — 인증 실패
            case "INVALID_REFRESH_TOKEN"  -> HttpStatus.UNAUTHORIZED;

            // 403 — 접근 권한 없음
            case "NOT_ACTIVE"             -> HttpStatus.FORBIDDEN;
            case "FORBIDDEN"              -> HttpStatus.FORBIDDEN;

            // 400 — 잘못된 입력 (기본값)
            default                       -> HttpStatus.BAD_REQUEST;
        };
    }
}