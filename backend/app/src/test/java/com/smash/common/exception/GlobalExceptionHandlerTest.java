package com.smash.common.exception;

import com.smash.common.response.ApiResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    @DisplayName("LAST_ADMIN: HTTP 400 으로 내려가고 코드와 메시지가 응답 본문에 담긴다")
    void lastAdmin_isBadRequest_withCodeAndMessage() {
        BusinessException e = new BusinessException(
                "LAST_ADMIN", "마지막 임원은 탈퇴할 수 없습니다. 다른 임원을 먼저 지정해 주세요.");

        ResponseEntity<ApiResponse<Void>> response = handler.handleBusinessException(e);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isFalse();
        assertThat(response.getBody().getError().getCode()).isEqualTo("LAST_ADMIN");
        assertThat(response.getBody().getError().getMessage())
                .isEqualTo("마지막 임원은 탈퇴할 수 없습니다. 다른 임원을 먼저 지정해 주세요.");
    }

    @Test
    @DisplayName("투표·모집 기간 검증 코드(INVALID_CLOSE_TIME, INVALID_PERIOD)도 HTTP 400")
    void validationCodes_areBadRequest() {
        assertThat(handler.handleBusinessException(
                new BusinessException("INVALID_CLOSE_TIME", "마감 시각은 지금보다 이후로 설정해 주세요."))
                .getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(handler.handleBusinessException(
                new BusinessException("INVALID_PERIOD", "모집 종료 시각은 시작 시각보다 이후로 설정해 주세요."))
                .getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
