package com.smash.api.admin;

import com.smash.api.auth.MemberRegisterRequest;
import com.smash.api.auth.MemberRegisterResponse;
import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

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
}