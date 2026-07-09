package com.smash.api.admin;

import com.smash.api.auth.MemberRegisterRequest;
import com.smash.api.auth.MemberRegisterResponse;
import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class AdminMemberController {

    private final AdminMemberService adminMemberService;

    // A-1. 단건 등록
    @PostMapping("/api/v1/admin/members")
    public ResponseEntity<ApiResponse<MemberRegisterResponse>> registerMember(
            @RequestBody @Valid MemberRegisterRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                adminMemberService.registerMember(request)));
    }

    // A-2. 대량 등록
    @PostMapping("/api/v1/admin/members/bulk")
    public ResponseEntity<ApiResponse<MemberRegisterResponse.BulkResponse>> registerMembers(
            @RequestBody MemberRegisterRequest.BulkRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                adminMemberService.registerMembers(request)));
    }

    // 지원자(PENDING) 목록 조회
    @GetMapping("/api/v1/admin/members/pending")
    public ResponseEntity<ApiResponse<List<MemberRegisterResponse>>> getPendingApplicants() {
        return ResponseEntity.ok(ApiResponse.success(
                adminMemberService.getPendingApplicants()));
    }

    // 불합격 처리
    @PatchMapping("/api/v1/admin/members/{userId}/reject")
    public ResponseEntity<ApiResponse<Void>> reject(@PathVariable Long userId) {
        adminMemberService.reject(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 불합격 취소 (복구)
    @PatchMapping("/api/v1/admin/members/{userId}/restore")
    public ResponseEntity<ApiResponse<Void>> restore(@PathVariable Long userId) {
        adminMemberService.restore(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}