package com.smash.api.transport;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class TransportController {

    private final TransportService transportService;

    // 택시 그룹 배정 (ADMIN)
    @PostMapping("/api/v1/admin/activities/{activityId}/transport-groups")
    public ResponseEntity<ApiResponse<List<TransportGroupResponse>>> assign(
            @PathVariable Long activityId,
            @RequestBody @Valid TransportGroupRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                transportService.assign(activityId, request)
        ));
    }

    // 택시 그룹 조회
    @GetMapping("/api/v1/activities/{activityId}/transport-groups")
    public ResponseEntity<ApiResponse<List<TransportGroupResponse>>> getGroups(
            @PathVariable Long activityId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                transportService.getGroups(activityId)
        ));
    }

    // 택시 그룹 초기화 (ADMIN)
    @DeleteMapping("/api/v1/admin/activities/{activityId}/transport-groups")
    public ResponseEntity<ApiResponse<Void>> reset(
            @PathVariable Long activityId
    ) {
        transportService.reset(activityId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

}
