package com.smash.api.transport;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class TaxiSettlementController {

    private final TaxiSettlementService taxiSettlementService;

    // 정산 생성
    @PostMapping("/api/v1/activities/{activityId}/transport-groups/{groupId}/settlement")
    public ResponseEntity<ApiResponse<TaxiSettlementResponse>> create(
            @PathVariable Long activityId,
            @PathVariable Long groupId,
            @RequestBody TaxiSettlementRequest request,
            @AuthenticationPrincipal Long userId

    ) {
        return ResponseEntity.ok(ApiResponse.success(taxiSettlementService.create(activityId, groupId, request, userId)));
    }

    // 정산 조회
    @GetMapping("/api/v1/activities/{activityId}/transport-groups/{groupId}/settlement")
    public ResponseEntity<ApiResponse<TaxiSettlementResponse>> getSettlement(
            @PathVariable Long activityId,
            @PathVariable Long groupId
    ) {
        return ResponseEntity.ok(ApiResponse.success(taxiSettlementService.getSettlement(activityId, groupId)));
    }

    // 납부 확인 토글
    @PatchMapping("/api/v1/settlements/{settlementId}/payments/{userId}")
    public ResponseEntity<ApiResponse<Void>> togglePayment(
            @PathVariable Long settlementId,
            @PathVariable Long userId
    ) {
        taxiSettlementService.togglePayment(settlementId, userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 정산 삭제
    @DeleteMapping("/api/v1/settlements/{settlementId}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long settlementId
    ) {
        taxiSettlementService.delete(settlementId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
