package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.MemberAvailability;
import com.smash.domain.group.MemberAvailabilityRepository;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AssignmentService {

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final MemberAvailabilityRepository memberAvailabilityRepository;

    // C-3: DB에는 아무것도 저장하지 않는다. previewToken/basedOnMemberIds는 클라이언트가
    // confirm 요청에 그대로 되돌려줘야 하는 추적용 값.
    @Transactional(readOnly = true)
    public AssignmentPreviewResult preview() {
        List<User> unassignedMembers = userRepository.findByGroupIdIsNullAndStatusAndRole(Status.ACTIVE, Role.MEMBER);
        List<Long> memberIds = unassignedMembers.stream().map(User::getId).toList();
        Map<Long, List<Long>> availabilityByUser = groupAvailabilityByUser(memberIds);
        List<Group> groups = groupRepository.findAll();
        List<Long> groupIds = groups.stream().map(Group::getId).toList();

        List<MemberAvailabilityInput> inputs = unassignedMembers.stream()
                .map(u -> new MemberAvailabilityInput(u.getId(), availabilityByUser.getOrDefault(u.getId(), List.of())))
                .toList();
        AssignmentResult result = AssignmentAlgorithm.assign(inputs, groupIds);

        Map<Long, String> nameById = unassignedMembers.stream()
                .collect(Collectors.toMap(User::getId, User::getName));
        Map<Long, Group> groupById = groups.stream().collect(Collectors.toMap(Group::getId, g -> g));

        List<MemberAssignmentView> assignments = result.assignments().stream()
                .map(a -> new MemberAssignmentView(
                        a.userId(), nameById.get(a.userId()), a.groupId(),
                        availabilityByUser.getOrDefault(a.userId(), List.of())))
                .toList();
        List<MemberUnassignedView> unassigned = result.unassigned().stream()
                .map(u -> new MemberUnassignedView(u.userId(), nameById.get(u.userId()), u.reason()))
                .toList();
        List<GroupCount> groupDistribution = result.groupDistribution().entrySet().stream()
                .map(e -> {
                    Group group = groupById.get(e.getKey());
                    return new GroupCount(group.getId(), group.getDayOfWeek(), group.getTimeSlot(), e.getValue());
                })
                .toList();

        return new AssignmentPreviewResult(UUID.randomUUID().toString(), memberIds, assignments, unassigned, groupDistribution);
    }

    // C-4: 정합성 3중 체크 - ① basedOnMemberIds 대조 ② 존재하지 않는 groupId면 전체 롤백
    // ③ WHERE group_id IS NULL 조건부 UPDATE로 이미 배정된 건 skip.
    @Transactional
    public ConfirmResult confirm(List<Long> basedOnMemberIds, List<Assignment> assignments) {
        Set<Long> currentUnassigned = userRepository.findByGroupIdIsNullAndStatusAndRole(Status.ACTIVE, Role.MEMBER).stream()
                .map(User::getId)
                .collect(Collectors.toSet());
        if (!currentUnassigned.equals(new HashSet<>(basedOnMemberIds))) {
            throw new BusinessException(ErrorCode.ASSIGNMENT_CONFLICT);
        }

        Set<Long> validGroupIds = groupRepository.findAll().stream().map(Group::getId).collect(Collectors.toSet());
        for (Assignment assignment : assignments) {
            if (!validGroupIds.contains(assignment.groupId())) {
                throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND);
            }
        }

        int assignedCount = 0;
        List<SkippedMember> skipped = new ArrayList<>();
        for (Assignment assignment : assignments) {
            int updated = userRepository.assignGroupIfUnassigned(assignment.userId(), assignment.groupId());
            if (updated == 0) {
                skipped.add(new SkippedMember(assignment.userId(), "ALREADY_ASSIGNED"));
            } else {
                assignedCount++;
            }
        }
        return new ConfirmResult(assignedCount, skipped);
    }

    // C-5: 임원의 개별 수정. confirm과 달리 이미 배정된 조도 덮어쓸 수 있다.
    @Transactional
    public void updateMemberGroup(Long userId, Long groupId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        if (!groupRepository.existsById(groupId)) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND);
        }
        user.assignGroup(groupId);
    }

    @Transactional(readOnly = true)
    public List<UnassignedMemberView> getUnassignedMembers() {
        List<User> users = userRepository.findByGroupIdIsNullAndStatusAndRole(Status.ACTIVE, Role.MEMBER);
        Map<Long, List<Long>> availabilityByUser = groupAvailabilityByUser(users.stream().map(User::getId).toList());
        return users.stream()
                .map(u -> new UnassignedMemberView(u.getId(), u.getName(), availabilityByUser.getOrDefault(u.getId(), List.of())))
                .toList();
    }

    private Map<Long, List<Long>> groupAvailabilityByUser(List<Long> userIds) {
        return memberAvailabilityRepository.findByUserIdIn(userIds).stream()
                .collect(Collectors.groupingBy(MemberAvailability::getUserId,
                        HashMap::new,
                        Collectors.mapping(MemberAvailability::getGroupId, Collectors.toList())));
    }
}
