package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.service.InviteCodeService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/invite-codes")
@RequiredArgsConstructor
public class InviteCodeController {

    private final InviteCodeService inviteCodeService;

    @PostMapping
    public ApiResponse<InviteCodeResponse> create() {
        return ApiResponse.success(InviteCodeResponse.from(inviteCodeService.create()));
    }

    @GetMapping
    public ApiResponse<List<InviteCodeResponse>> getAll() {
        return ApiResponse.success(inviteCodeService.getAll().stream().map(InviteCodeResponse::from).toList());
    }

    @PatchMapping("/{id}")
    public ApiResponse<Void> updateActive(@PathVariable Long id, @Valid @RequestBody InviteCodeActiveRequest request) {
        inviteCodeService.updateActive(id, request.isActive());
        return ApiResponse.success(null);
    }
}
