package com.smash.api.admin;

import com.smash.api.auth.MemberRegisterRequest;
import com.smash.api.auth.MemberRegisterResponse;
import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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

    // 전체 유저 목록 조회
    @GetMapping("/api/v1/admin/members")
    public ResponseEntity<ApiResponse<List<MemberRegisterResponse>>> getAllMembers() {
        return ResponseEntity.ok(ApiResponse.success(adminMemberService.getAllMembers()));
    }

    // 특정 조 소속 부원 목록
    @GetMapping("/api/v1/admin/groups/{groupId}/members")
    public ResponseEntity<ApiResponse<List<MemberRegisterResponse>>> getGroupMembers(
            @PathVariable Long groupId) {
        return ResponseEntity.ok(ApiResponse.success(
                adminMemberService.getGroupMembers(groupId)));
    }

    // 지원자 삭제
    @DeleteMapping("/api/v1/admin/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> deleteMember(@PathVariable Long userId) {
        adminMemberService.deleteMember(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 부원 상세 조회
    @GetMapping("/api/v1/admin/members/{userId}")
    public ResponseEntity<ApiResponse<MemberDetailResponse>> getMember(
            @PathVariable Long userId,
            @AuthenticationPrincipal Long adminId) {
        return ResponseEntity.ok(ApiResponse.success(
                adminMemberService.getMember(userId, adminId)));
    }

    // 권한 변경
    @PatchMapping("/api/v1/admin/members/{userId}/role")
    public ResponseEntity<ApiResponse<Void>> changeRole(
            @PathVariable Long userId,
            @RequestParam String role) {
        adminMemberService.changeRole(userId, role);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 개인 메모 추가
    @PostMapping("/api/v1/admin/members/{userId}/notes")
    public ResponseEntity<ApiResponse<Void>> addNote(
            @PathVariable Long userId,
            @RequestParam String content,
            @AuthenticationPrincipal Long adminId) {
        adminMemberService.addNote(userId, adminId, content);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 개인 메모 삭제
    @DeleteMapping("/api/v1/admin/members/notes/{noteId}")
    public ResponseEntity<ApiResponse<Void>> deleteNote(
            @PathVariable Long noteId) {
        adminMemberService.deleteNote(noteId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 부원 정보 수정
    @PatchMapping("/api/v1/admin/members/{userId}/info")
    public ResponseEntity<ApiResponse<Void>> updateMemberInfo(
            @PathVariable Long userId,
            @RequestBody UpdateMemberInfoRequest request) {
        adminMemberService.updateMemberInfo(userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}