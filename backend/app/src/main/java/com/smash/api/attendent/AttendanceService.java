package com.smash.api.attendent;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AttendanceService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final ActivityRepository activityRepository;
    private final ParticipationRepository participationRepository;

    // E-1. 조별 충족 현황
    @Transactional(readOnly = true)
    public AttendanceResponse getAttendance(Long groupId, int year, int month) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 조입니다."
                ));
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end = yearMonth.atEndOfMonth();

        // 그 달 본인 조 정규 활동일 수 (guaranteed)
        int guaranteedCount = activityRepository
                .findRegularActivitiesByGroupAndMonth(groupId, start, end).size();

        // 해당 조 부원 목록
        List<User> members = userRepository.findByGroupId(groupId);

        List<AttendanceResponse.MemberAttendance> memberAttendances = new ArrayList<>();

        for (User member : members) {
            int fulfilled = participationRepository
                    .countFulfilledByUserAndMonth(member.getId(), start, end);
            int shortfall = Math.max(0, guaranteedCount - fulfilled);

            memberAttendances.add(AttendanceResponse.MemberAttendance.builder()
                    .userId(member.getId())
                    .name(member.getName())
                    .fulfilled(fulfilled)
                    .guaranteed(guaranteedCount)
                    .shortfall(shortfall)
                    .isShortfall(shortfall > 0)
                    .build());
        }

        return AttendanceResponse.builder()
                .groupId(groupId)
                .groupLabel(group.getLabel())
                .year(year).month(month)
                .guaranteedCount(guaranteedCount)
                .members(memberAttendances)
                .build();

    }

    // E-2. 미달 부원 필터
    @Transactional(readOnly = true)
    public List<ShortfallResponse> getShortfall(int year, int month) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end = yearMonth.atEndOfMonth();

        List<Group> allGroups = groupRepository.findAll();
        List<ShortfallResponse> result = new ArrayList<>();


        for (Group group : allGroups) {
            int guaranteedCount = activityRepository
                    .findRegularActivitiesByGroupAndMonth(group.getId(), start, end).size();

            List<User> members = userRepository.findByGroupId(group.getId());

            for (User member : members) {
                int fulfilled = participationRepository
                        .countFulfilledByUserAndMonth(member.getId(), start, end);
                int shortfall = Math.max(0, guaranteedCount - fulfilled);

                if (shortfall > 0) {
                    result.add(ShortfallResponse.builder()
                            .userId(member.getId())
                            .name(member.getName())
                            .groupLabel(group.getLabel())
                            .fulfilled(fulfilled)
                            .guaranteed(guaranteedCount)
                            .shortfall(shortfall)
                            .build());
                }
            }
        }

        return result;
    }

    // E-3. 타조참 인원
    @Transactional(readOnly = true)
    public List<OtherGroupResponse> getOtherGroup(int year, int month) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end = yearMonth.atEndOfMonth();

        List<User> allMembers = userRepository.findAllActiveMembers();
        List<OtherGroupResponse> result = new ArrayList<>();

        for (User member : allMembers) {
            List<Participation> otherGroupList = participationRepository
                    .findOtherGroupByUserAndMonth(member.getId(), start, end);

            if (!otherGroupList.isEmpty()) {
                List<OtherGroupResponse.ActivityInfo> activities = otherGroupList.stream()
                        .map(p -> OtherGroupResponse.ActivityInfo.builder()
                                .activityId(p.getActivity().getId())
                                .date(p.getActivity().getActivityDate())
                                .groupLabel(p.getActivity().getGroup().getLabel())
                                .build())
                        .toList();
                result.add(OtherGroupResponse.builder()
                        .userId(member.getId())
                        .name(member.getName())
                        .count(otherGroupList.size())
                        .activities(activities)
                        .build());
            }
        }

        return result;
    }
}
