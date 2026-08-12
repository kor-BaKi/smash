package com.smash.api.transport;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.TransportGroup;
import com.smash.domain.transport.TransportGroupRepository;
import com.smash.domain.transport.TransportMember;
import com.smash.domain.transport.TransportMemberRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TransportService {

    private final TransportGroupRepository transportGroupRepository;
    private final TransportMemberRepository transportMemberRepository;
    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;


    // 택시 그룹 배정 (ADMIN)
    // 그룹 삭제 → 멤버 삭제 → 새 그룹 생성 → 새 멤버 생성이 전부 성공하거나 전부 실패해야 함
    // 중간에 실패하면 자동 롤백
    @Transactional
    public List<TransportGroupResponse> assign(
            Long activityId,
            TransportGroupRequest request
    ) {
        Activity activity = getActivity(activityId);

        // 기존 배정 초기화
        List<TransportGroup> existing =         // 이 활동의 기존 그룹 목록을 가져옴 -> [1호차, 2호차]
                transportGroupRepository.findByActivityOrderByGroupNumber(activity);
        for (TransportGroup group : existing) {    // 2. 각 그룹의 탑승자(자식)를 먼저 삭제
            // 1호차 탑승자 삭제 → 2호차 탑승자 삭제
            transportMemberRepository.deleteByTransportGroup(group);
        }
        // 3. 그룹(부모) 삭제
        // 자식이 없어졌으니 이제 안전하게 삭제 가능
        transportGroupRepository.deleteByActivity(activity);

        // 새로 배정
            int groupNumber = 1;
            for (TransportGroupRequest.Group groupRequest : request.getGroups()) {

                // TransportGroup 저장
                final TransportGroup savedGroup = transportGroupRepository.save(
                        TransportGroup.builder()
                                .activity(activity)
                                .groupNumber(groupNumber)
                                .build()
                );
                groupNumber++;
                // TransportMember 저장
                for (Long memberId : groupRequest.getMemberIds()) {
                    User user = userRepository.findById(memberId)
                            .orElseThrow(() -> new BusinessException(
                                    "RESOURCE_NOT_FOUND",
                                    "존재하지 않는 부원입니다."
                            ));
                    transportMemberRepository.save(
                            TransportMember.builder()
                                    .transportGroup(savedGroup)
                                    .user(user)
                                    .build()
                    );
                }
        }
        return getGroups(activityId);
    }

    // 택시 그룹 조회
    @Transactional
    public List<TransportGroupResponse> getGroups(Long activityId) {
        Activity activity = getActivity(activityId);
        List<TransportGroup> groups =
                transportGroupRepository.findByActivityOrderByGroupNumber(activity);

        return groups.stream()
                .map(group -> {
                    List<TransportMember> members =
                            transportMemberRepository.findByTransportGroup(group);
                    return TransportGroupResponse.of(group, members);
                })
                .toList();
    }

    // 택시 그룹 초기화 (ADMIN)
    public void reset(Long activityId) {
        Activity activity = getActivity(activityId);
        List<TransportGroup> groups =
                transportGroupRepository.findByActivityOrderByGroupNumber(activity);
        for (TransportGroup group : groups) {
            transportMemberRepository.deleteByTransportGroup(group);
        }
        transportGroupRepository.deleteByActivity(activity);
    }

    private Activity getActivity(Long activityId) {
        return activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 활동입니다."
                ));
    }

}
