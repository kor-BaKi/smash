package com.smash.api.assignment;

import com.smash.common.exception.BusinessException;
import com.smash.domain.availability.MemberAvailability;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AssignmentService {

    /*
    선택지 적은 부원부터 순서대로
    → 가능 조 중 현재 인원 가장 적은 조 선택
    → 동점이면 id 오름차순 (결정적 결과 보장)
    */

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final MemberAvailabilityRepository availabilityRepository;

    // 가능 요일 제출
    @Transactional
    public List<AvailabilityResponse> submitAvailability(Long userId, AvailabilityRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
                ));

        if (user.getGroupId() != null) {
            throw new BusinessException("ALREADY_ASSIGNED", "이미 배정이 완료되어 수정할 수 없습니다.");
        }

        // 기존 가능요일 전체 삭제 후 재저장 (덮어쓰기)
        availabilityRepository.deleteByUser(user);

        List<MemberAvailability> availabilities = new ArrayList<>();
        for (Long groupId : request.getGroupIds()) {
            Group group = groupRepository.findById(groupId)
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."
                    ));
            availabilities.add(MemberAvailability.builder()
                    .user(user)
                    .group(group)
                    .build());
        }

        availabilityRepository.saveAll(availabilities);

        return availabilities.stream()
                .map(a -> AvailabilityResponse.builder()
                        .groupId(a.getGroup().getId())
                        .dayOfWeek(a.getGroup().getDayOfWeek())
                        .timeSlot(a.getGroup().getTimeSlot())
                        .label(a.getGroup().getLabel())
                        .build())
                .toList();
    }

    // 본인 가능 요일 조회
    @Transactional
    public List<AvailabilityResponse> getMyAvailability(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
                ));
        
        return availabilityRepository.findByUser(user)
                .stream()
                .map(a -> AvailabilityResponse.builder()
                        .groupId(a.getGroup().getId())
                        .dayOfWeek(a.getGroup().getDayOfWeek())
                        .timeSlot(a.getGroup().getTimeSlot())
                        .label(a.getGroup().getLabel())
                        .build())
                .toList();
    }

    // 자동 배정
    @Transactional
    public AssignmentPreviewResponse preview() {
        // 1. 미배정 부원 조회
        List<User> unassignedMembers = userRepository.findUnassignedMembers();
        List<Group> allGroups = groupRepository.findAll();

        // 2. 조별 현재 인원 카운터
        Map<Long, Integer> groupCount = new HashMap<>(); // Map<조id, 현재인원>
        for (Group group : allGroups) {
            groupCount.put(group.getId(), 0);
        }

        // 3. 부원별 가능 조 목록 구성
        Map<Long, List<Long>> memberAvailableGroups = new HashMap<>(); // Map<부원id, [가능한 조id 목록]>
        for (User member : unassignedMembers) {
            List<Long> groupIds = availabilityRepository.findByUser(member)
                    .stream()
                    .map(a -> a.getGroup().getId())
                    .toList();
            memberAvailableGroups.put(member.getId(), groupIds);
        }

        // 4. 선택지 적은 순으로 정렬 (선택지 개수가 같으면  id 오름차순)
        List<User> sorted = unassignedMembers.stream()
                .sorted(Comparator
                        .comparingInt((User u ) ->
                                memberAvailableGroups.get(u.getId()).size())
                        .thenComparingLong(User::getId))
                .toList();

        // 5. 그리디 배정
        List<AssignmentPreviewResponse.AssignmentItem> assignments = new ArrayList<>();
        List<AssignmentPreviewResponse.UnassignedItem> unassigned = new ArrayList<>();

        for (User member : sorted) {
            List<Long> availableGroupIds = memberAvailableGroups.get(member.getId());

            // 가능 요일 제출하지 않은 부원은 배정 불가 처리하고 continue로 건너뛰기
            if (availableGroupIds.isEmpty()) {
                unassigned.add(AssignmentPreviewResponse.UnassignedItem.builder()
                        .userId(member.getId())
                        .name(member.getName()).reason("NO_AVAILABILITY").build());
                continue;
            }

            // 가능 조 중 인원 가장 적은 조 선택 (동점이면 id 오름차순)
            Long targetGroupId = availableGroupIds.stream()
                    .min(Comparator
                            .comparingInt((Long gId) -> groupCount.get(gId))
                            .thenComparingLong(gId -> gId))
                    .orElseThrow();

            groupCount.put(targetGroupId, groupCount.get(targetGroupId) + 1);

            assignments.add(AssignmentPreviewResponse.AssignmentItem.builder()
                    .userId(member.getId())
                    .name(member.getName())
                    .assignedGroupId(targetGroupId)
                    .availableGroupIds(availableGroupIds)
                    .build());
        }

        // 6. 조별 분포
        Map<Long, Group> groupMap = allGroups.stream()
                .collect(Collectors.toMap(Group::getId, g -> g));

        List<AssignmentPreviewResponse.GroupDistribution> distribution = groupCount.entrySet()
                .stream()
                .map(e -> AssignmentPreviewResponse.GroupDistribution.builder()
                        .groupId(e.getKey())
                        .label(groupMap.get(e.getKey()).getLabel())
                        .count(e.getValue()).build())
                .toList();

        // 7. previewToken 생성 (정합성 검증용)
        String previewToken = UUID.randomUUID().toString();
        List<Long> basedOnMemberIds = unassignedMembers.stream()
                .map(User::getId)
                .toList();

        return AssignmentPreviewResponse.builder()
                .previewToken(previewToken)
                .basedOnMemberIds(basedOnMemberIds)
                .assignments(assignments)
                .unassigned(unassigned)
                .groupDistribution(distribution)
                .build();
    }

    // 배정 확정
    @Transactional
    public void confirm(AssignmentConfirmRequest request) {
        // 정합성 검증 : 현재 미배정 부원 집합과 대조
        List<Long> currentUnassignedIds = userRepository.findUnassignedMembers()
                .stream()
                .map(User::getId)
                .sorted()
                .toList();

        List<Long> basedOnIds = request.getBasedOnMemberIds()
                .stream()
                .sorted()
                .toList();

        if (!currentUnassignedIds.equals(basedOnIds)) {
            throw new BusinessException("ASSIGNMENT_CONFLICT",
                    "배정 대상이 변경되었습니다. 미리보기를 다시 실행해주세요.");
        }

        // 조건부 UPDATE: 이미 배정된 부원은 건너뜀
        for (AssignmentConfirmRequest.AssignmentItem item : request.getAssignments()) {
            User user = userRepository.findById(item.getUserId())
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "존재하지 않는 유저 입니다."
                    ));

            if (user.getGroupId() != null) {
                continue; // 이미 배정된 부원 skip
            }

            groupRepository.findById(item.getGroupId())
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."
                    ));

            user.assignGroup(item.getGroupId());
        }
    }

    // 개벌 배정 수정
    @Transactional
    public void assignMember(Long userId, Long groupId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."
                ));

        groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다. "
                ));

        user.assignGroup(groupId);
    }

    // 미배정자 목록
    @Transactional
    public List<AssignmentPreviewResponse.UnassignedItem> getUnassignedMembers() {
        return userRepository.findUnassignedMembers()
                .stream()
                .map(user -> AssignmentPreviewResponse.UnassignedItem.builder()
                        .userId(user.getId())
                        .name(user.getName())
                        .reason("NO_AVAILABILITY")
                        .build())
                .toList();
    }
}
