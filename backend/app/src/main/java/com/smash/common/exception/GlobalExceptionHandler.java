package com.smash.common.exception;

import com.smash.common.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // 우리가 직접 더닞는 비즈니스 에러. 가입코드 오류, 투표 마감 등
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(BusinessException e) {
        return ResponseEntity
                .badRequest() // 400 상태코드
                .body(ApiResponse.fail(e.getCode(), e.getMessage())); // .body()로 실제 응답 데이터를 담음
    }

    /*
    * @Valid로 요청 데이터 검증 실패할 때 자동으로 던져짐. ex. 학번을 안보냈을 때
    * @Valid로 검증 실패하면 여러 필드에서 동시에 에러가 날 수 있음
    * .getFieldErrors()로 에러 목록을 가져오고,
    * .getFirst()로 첫 번째 에러 메시지만 꺼내서 응답에 담음
    * */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult()
                .getFieldErrors()
                .getFirst()
                .getDefaultMessage();
        return ResponseEntity
                .badRequest()
                .body(ApiResponse.fail("INVALID_INPUT", message));
    }

    // 모든 컨트롤러에서 발생하는 예외를 여기서 한 곳에 모아서 처리
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception e) {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)  // // 500 상태코드
                .body(ApiResponse.fail("SERVER_ERROR", "서버 오류가 발생했습니다."));
    }
}