package com.smash.api.group;

import com.smash.common.exception.BusinessException;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
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
            if (!groupRepository.existsAllByDayOfWeekAndTimeSlot(
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
}
