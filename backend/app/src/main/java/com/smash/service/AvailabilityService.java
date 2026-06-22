package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.MemberAvailability;
import com.smash.domain.group.MemberAvailabilityRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AvailabilityService {

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final MemberAvailabilityRepository memberAvailabilityRepository;

    // C-1: 배정 전(group_id NULL)에만 제출 가능. 기존 제출은 전체삭제 후 재저장.
    @Transactional
    public List<Group> submitAvailability(Long userId, List<Long> groupIds) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        if (user.getGroupId() != null) {
            throw new BusinessException(ErrorCode.ALREADY_ASSIGNED);
        }

        Set<Long> distinctGroupIds = new HashSet<>(groupIds);
        List<Group> groups = groupRepository.findAllById(distinctGroupIds);
        if (groups.size() != distinctGroupIds.size()) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND);
        }

        memberAvailabilityRepository.deleteByUserId(userId);
        distinctGroupIds.forEach(groupId ->
                memberAvailabilityRepository.save(MemberAvailability.create(userId, groupId)));

        return groups;
    }

    @Transactional(readOnly = true)
    public AvailabilityStatus getAvailability(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        List<Long> groupIds = memberAvailabilityRepository.findByUserId(userId).stream()
                .map(MemberAvailability::getGroupId)
                .toList();
        List<Group> groups = groupRepository.findAllById(groupIds);

        return new AvailabilityStatus(groups, user.getGroupId() != null, user.getGroupId());
    }
}
