package com.smash.api.invite;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class InviteCodeController {

    private final InviteCodeService inviteCodeService;

    @PostMapping("/api/v1/admin/invite-codes")
    public ResponseEntity<ApiResponse<InviteCodeResponse>> createInviteCode() {
        return ResponseEntity.ok(ApiResponse.success(inviteCodeService.createInviteCode()));
    }

    @GetMapping("/api/v1/admin/invite-codes")
    public ResponseEntity<ApiResponse<List<InviteCodeResponse>>> getInviteCodes() {
        return ResponseEntity.ok(ApiResponse.success(inviteCodeService.getInviteCodes()));
    }

    @PatchMapping("/api/v1/admin/invite-codes/{id}")
    public ResponseEntity<ApiResponse<Void>> toggleInviteCode(
            @PathVariable Long id,
            @RequestBody @Valid InviteCodeToggleRequest request
    ) {
        inviteCodeService.toggleInviteCode(id, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
