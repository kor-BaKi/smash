package com.smash.common.exception;

import com.smash.common.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

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

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException e) {
        return ResponseEntity
                .status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(ApiResponse.fail("METHOD_NOT_ALLOWED", "지원하지 않는 요청 방식입니다."));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNoResource(NoResourceFoundException e) {
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.fail("RESOURCE_NOT_FOUND", "요청한 주소를 찾을 수 없습니다."));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> handleUploadTooLarge(MaxUploadSizeExceededException e) {
        log.warn("[UploadTooLarge] {}", e.getMessage());
        return ResponseEntity
                .status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(ApiResponse.fail("FILE_TOO_LARGE", "파일 용량이 너무 큽니다."));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnreadable(HttpMessageNotReadableException e) {
        return ResponseEntity
                .badRequest()
                .body(ApiResponse.fail("INVALID_INPUT", "요청 형식이 올바르지 않습니다."));
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

            // 429 - 요청이 너무 많음 (로그인 시도 제한)
            case "TOO_MANY_ATTEMPTS"      -> HttpStatus.TOO_MANY_REQUESTS;

            // 403 — 접근 권한 없음
            case "NOT_ACTIVE"             -> HttpStatus.FORBIDDEN;
            case "FORBIDDEN"              -> HttpStatus.FORBIDDEN;
            case "NOT_ALLOWED"            -> HttpStatus.FORBIDDEN;

            // 400 — 잘못된 입력 (기본값)
            default                       -> HttpStatus.BAD_REQUEST;
        };
    }
}