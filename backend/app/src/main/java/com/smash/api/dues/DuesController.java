package com.smash.api.dues;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class DuesController {

    private final DuesService duesService;

    // 전체 납부 현황 조회
    @GetMapping("/api/v1/admin/dues")
    public ResponseEntity<ApiResponse<List<DuesResponse>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success(duesService.getAll()));
    }

    // 납부 처리
    @PostMapping("/api/v1/admin/dues/{userId}")
    public ResponseEntity<ApiResponse<Void>> pay(
            @PathVariable Long userId
    ) {
        duesService.pay(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 납부 취소
    @DeleteMapping("/api/v1/admin/dues/{userId}")
    public ResponseEntity<ApiResponse<Void>> cancel(@PathVariable Long userId) {
        duesService.cancel(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 전체 초기화
    @DeleteMapping("/api/v1/admin/dues")
    public ResponseEntity<ApiResponse<Void>> reset() {
        duesService.reset();
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
