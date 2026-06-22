package com.smash.common;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    INVALID_INVITE_CODE(HttpStatus.BAD_REQUEST, "유효하지 않은 가입코드입니다."),
    STUDENT_NO_NOT_FOUND(HttpStatus.BAD_REQUEST, "사전등록된 학번을 찾을 수 없습니다."),
    ALREADY_REGISTERED(HttpStatus.CONFLICT, "이미 가입된 학번입니다."),
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "학번 또는 비밀번호가 올바르지 않습니다."),
    INVALID_REFRESH_TOKEN(HttpStatus.UNAUTHORIZED, "유효하지 않은 리프레시 토큰입니다."),
    RESOURCE_NOT_FOUND(HttpStatus.NOT_FOUND, "요청한 리소스를 찾을 수 없습니다.");

    private final HttpStatus status;
    private final String message;

    ErrorCode(HttpStatus status, String message) {
        this.status = status;
        this.message = message;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getMessage() {
        return message;
    }
}
