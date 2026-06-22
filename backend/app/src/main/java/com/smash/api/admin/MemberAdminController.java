package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.domain.user.User;
import com.smash.service.MemberRegisterCommand;
import com.smash.service.MemberService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class MemberAdminController {

    private final MemberService memberService;

    @PostMapping("/api/v1/admin/members")
    public ApiResponse<MemberCreateResponse> create(@Valid @RequestBody MemberCreateRequest request) {
        User user = memberService.registerPending(
                request.name(), request.studentNo(), request.department(), request.phone(), request.joinTerm());
        return ApiResponse.success(MemberCreateResponse.from(user));
    }

    // A-2 명세: 부분 성공을 207 Multi-Status로 표현.
    @PostMapping("/api/v1/admin/members/bulk")
    public ResponseEntity<ApiResponse<MemberBulkCreateResponse>> createBulk(
            @Valid @RequestBody MemberBulkCreateRequest request) {
        List<MemberRegisterCommand> commands = request.members().stream()
                .map(item -> new MemberRegisterCommand(
                        item.name(), item.studentNo(), item.department(), item.phone(), item.joinTerm()))
                .toList();
        var result = memberService.registerPendingBulk(commands);
        return ResponseEntity.status(HttpStatus.MULTI_STATUS)
                .body(ApiResponse.success(MemberBulkCreateResponse.from(result)));
    }
}
