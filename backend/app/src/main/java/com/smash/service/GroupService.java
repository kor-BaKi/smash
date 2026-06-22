package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.GroupSlot;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;

    @Transactional
    public List<Group> createGroups(List<GroupSlot> slots) {
        Set<GroupSlot> seen = new HashSet<>();
        List<Group> created = new ArrayList<>();

        for (GroupSlot slot : slots) {
            if (!seen.add(slot)) {
                continue; // 같은 요청 안에서의 중복
            }
            if (groupRepository.existsByDayOfWeekAndTimeSlot(slot.dayOfWeek(), slot.timeSlot())) {
                continue; // 이미 존재하는 조합은 skip (B-1 스펙)
            }
            created.add(groupRepository.save(Group.create(slot.dayOfWeek(), slot.timeSlot())));
        }
        return created;
    }

    @Transactional(readOnly = true)
    public List<Group> getGroups() {
        return groupRepository.findAll();
    }

    @Transactional(readOnly = true)
    public long countMembers(Long groupId) {
        return userRepository.countByGroupId(groupId);
    }

    @Transactional
    public void assignLeader(Long groupId, Long leaderUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        User newLeader = userRepository.findById(leaderUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        if (!groupId.equals(newLeader.getGroupId())) {
            throw new BusinessException(ErrorCode.INVALID_GROUP_MEMBER);
        }

        if (group.getLeaderUserId() != null) {
            userRepository.findById(group.getLeaderUserId()).ifPresent(User::unassignLeader);
        }
        group.assignLeader(leaderUserId);
        newLeader.assignAsLeader();
    }
}
