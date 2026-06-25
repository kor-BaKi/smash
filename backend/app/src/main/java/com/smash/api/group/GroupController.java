package com.smash.api.group;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    @PostMapping("/api/v1/admin/groups")
    public ResponseEntity<ApiResponse<Void>> createGroups(
            @RequestBody @Valid GroupRequest request
    ) {
        groupService.createGroups(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/api/v1/groups")
    public ResponseEntity<ApiResponse<List<GroupResponse>>> getGroups() {
        return ResponseEntity.ok(ApiResponse.success(groupService.getGroups()));
    }

    @PatchMapping("/api/v1/admin/groups/{groupId}/leader")
    public ResponseEntity<ApiResponse<Void>> assignLeader(
            @PathVariable Long groupId,
            @RequestBody @Valid GroupRequest.LeaderRequest request
    ) {
        groupService.assignLeader(groupId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
