package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupSlot;
import com.smash.service.GroupService;
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
public class GroupController {

    private final GroupService groupService;

    @PostMapping("/api/v1/admin/groups")
    public ApiResponse<GroupsCreateResponse> createGroups(@Valid @RequestBody GroupsCreateRequest request) {
        List<GroupSlot> slots = request.groups().stream()
                .map(item -> new GroupSlot(item.dayOfWeek(), item.timeSlot()))
                .toList();
        List<Group> created = groupService.createGroups(slots);
        List<GroupCreatedResponse> response = created.stream().map(GroupCreatedResponse::from).toList();
        return ApiResponse.success(new GroupsCreateResponse(response));
    }

    // B-2: 임원/부원 공통 조회. 권한 체크는 SecurityConfig의 인증 여부만으로 충분.
    @GetMapping("/api/v1/groups")
    public ApiResponse<List<GroupResponse>> getGroups() {
        List<GroupResponse> response = groupService.getGroups().stream()
                .map(group -> GroupResponse.of(group, groupService.countMembers(group.getId())))
                .toList();
        return ApiResponse.success(response);
    }

    @PatchMapping("/api/v1/admin/groups/{groupId}/leader")
    public ApiResponse<Void> assignLeader(@PathVariable Long groupId, @Valid @RequestBody LeaderAssignRequest request) {
        groupService.assignLeader(groupId, request.leaderUserId());
        return ApiResponse.success(null);
    }
}
