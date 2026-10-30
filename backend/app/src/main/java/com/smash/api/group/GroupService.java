package com.smash.api.group;

import com.smash.common.exception.BusinessException;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.user.Role;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;

    @Transactional
    public void createGroups(GroupRequest request) {
        for (GroupRequest.GroupItem item : request.getGroups()) { // 조 배열을 하나씩 순회하면서 이미 존재하는 조합이면 skip, 없으면 새로 저장. 중복 등록을 막는 로직.
            if (!groupRepository.existsByDayOfWeekAndTimeSlot(
                    item.getDayOfWeek(), item.getTimeSlot()
            )) {
                groupRepository.save(Group.builder()
                        .dayOfWeek(item.getDayOfWeek())
                        .timeSlot(item.getTimeSlot())
                        .build());
            }
        }
    }

    @Transactional(readOnly = true)
    public List<GroupResponse> getGroups() {
        return groupRepository.findAllOrderByDayOfWeek()
                .stream()
                .map(group -> {
                    int memberCount = userRepository.countByGroupId(group.getId());
                    return GroupResponse.of(group, memberCount);
                })
                .toList();
    }

    @Transactional
    public void assignLeader(Long groupId, GroupRequest.LeaderRequest request) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."
                ));

        userRepository.findById(request.getLeaderUserId())
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."
                ));

        group.assignLeader(request.getLeaderUserId());
    }

    @Transactional
    public void removeLeader(Long groupId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."));

        group.assignLeader(null);
    }

    @Transactional
    public GroupResponse assignViceLeader(Long groupId, Long userId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."));

        // 유저 존재 확인
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."));

        // 부조장은 임원(ADMIN)만 가능 (앱 후보 목록과 동일한 기준을 서버에서도 강제)
        if (user.getRole() != Role.ADMIN) {
            throw new BusinessException(
                    "INVALID_REQUEST", "임원만 부조장으로 지정할 수 있습니다.");
        }

        // 조장과 부조장은 같은 사람일 수 없음
        if (userId.equals(group.getLeaderUserId())) {
            throw new BusinessException(
                    "INVALID_REQUEST", "조장은 부조장으로 지정할 수 없습니다.");
        }

        group.assignViceLeader(userId);
        int memberCount = userRepository.countByGroupId(group.getId());
        return GroupResponse.of(group, memberCount);
    }

    @Transactional
    public GroupResponse removeViceLeader(Long groupId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."));
        group.assignViceLeader(null);
        int memberCount = userRepository.countByGroupId(group.getId());
        return GroupResponse.of(group, memberCount);
    }
}
