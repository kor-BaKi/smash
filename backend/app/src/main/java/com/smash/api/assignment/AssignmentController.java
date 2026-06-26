package com.smash.api.assignment;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class AssignmentController {

    private final AssignmentService assignmentService;

    @PutMapping("/api/v1/me/availability")
    public ResponseEntity<ApiResponse<List<AvailabilityResponse>>> submitAvailability(
            @AuthenticationPrincipal Long userId, // JWT에서 userId 꺼내기
            @RequestBody @Valid AvailabilityRequest request // JSON을 AvailabilityRequest로 변환 + 검증
    ) {
        return ResponseEntity.ok(ApiResponse.success( // HTTP 200으로 응답
                assignmentService.submitAvailability(userId, request) // 비즈니스 로직 실행
        ));
    }

    @GetMapping("/api/v1/me/availability")
    public ResponseEntity<ApiResponse<List<AvailabilityResponse>>> getMyAvailability(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                assignmentService.getMyAvailability(userId)));
    }

    @PostMapping("/api/v1/admin/assignment/preview")
    public ResponseEntity<ApiResponse<AssignmentPreviewResponse>> preview() {
        return ResponseEntity.ok(ApiResponse.success(assignmentService.preview()));
    }

    @PostMapping("/api/v1/admin/assignment/confirm")
    public ResponseEntity<ApiResponse<Void>> confirm(
            @RequestBody @Valid AssignmentConfirmRequest request
    ) {
        assignmentService.confirm(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PatchMapping("/api/v1/amdin/members/{userId}/group")
    public ResponseEntity<ApiResponse<Void>> assignMember(
            @PathVariable Long userId,
            @RequestBody Long groupId
    ) {
        assignmentService.assignMember(userId, groupId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/api/v1/amdin/members/unassigned")
    public ResponseEntity<ApiResponse<List<AssignmentPreviewResponse.UnassignedItem>>> getUnassigned() {
        return ResponseEntity.ok(ApiResponse.success(
                assignmentService.getUnassignedMembers()
        ));
    }
}
