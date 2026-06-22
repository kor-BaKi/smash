package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.service.Assignment;
import com.smash.service.AssignmentPreviewResult;
import com.smash.service.AssignmentService;
import com.smash.service.ConfirmResult;
import com.smash.service.UnassignedMemberView;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class AssignmentController {

    private final AssignmentService assignmentService;

    @PostMapping("/api/v1/admin/assignment/preview")
    public ApiResponse<AssignmentPreviewResponse> preview() {
        AssignmentPreviewResult result = assignmentService.preview();
        return ApiResponse.success(AssignmentPreviewResponse.from(result));
    }

    @PostMapping("/api/v1/admin/assignment/confirm")
    public ApiResponse<AssignmentConfirmResponse> confirm(@Valid @RequestBody AssignmentConfirmRequest request) {
        List<Assignment> assignments = request.assignments().stream()
                .map(item -> new Assignment(item.userId(), item.groupId()))
                .toList();
        ConfirmResult result = assignmentService.confirm(request.basedOnMemberIds(), assignments);
        return ApiResponse.success(AssignmentConfirmResponse.from(result));
    }

    @PatchMapping("/api/v1/admin/members/{userId}/group")
    public ApiResponse<Void> updateMemberGroup(
            @PathVariable Long userId, @Valid @RequestBody MemberGroupUpdateRequest request) {
        assignmentService.updateMemberGroup(userId, request.groupId());
        return ApiResponse.success(null);
    }

    @GetMapping("/api/v1/admin/members/unassigned")
    public ApiResponse<List<UnassignedMemberItem>> getUnassignedMembers() {
        List<UnassignedMemberView> views = assignmentService.getUnassignedMembers();
        return ApiResponse.success(views.stream().map(UnassignedMemberItem::from).toList());
    }
}
