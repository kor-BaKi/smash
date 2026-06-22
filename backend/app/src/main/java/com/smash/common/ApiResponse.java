package com.smash.common;

// 05-API명세.md 공통 응답 규칙: { success, data, error }
public record ApiResponse<T>(boolean success, T data, ErrorResponse error) {

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, data, null);
    }

    public static <T> ApiResponse<T> error(String code, String message) {
        return new ApiResponse<>(false, null, new ErrorResponse(code, message));
    }
}
