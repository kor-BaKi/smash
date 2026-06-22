package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// E영역: 전부 임원 전용·계산 기반(저장 안 함). 부원에게는 절대 노출하지 않는다 (CLAUDE.md 3.4).
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AttendanceService {

    private static final List<ParticipationType> FULFILLING_TYPES = List.of(ParticipationType.REGULAR, ParticipationType.CARRYOVER);

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final ActivityRepository activityRepository;
    private final ParticipationRepository participationRepository;

    // E-1
    public GroupAttendance getGroupAttendance(Long groupId, int year, int month) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd = monthStart.withDayOfMonth(monthStart.lengthOfMonth());

        int guaranteed = countGuaranteed(groupId, monthStart, monthEnd);
        List<User> members = userRepository.findByGroupIdAndStatusAndRole(groupId, Status.ACTIVE, Role.MEMBER);

        List<MemberAttendance> memberAttendances = members.stream()
                .map(member -> {
                    int fulfilled = countFulfilled(member.getId(), monthStart, monthEnd);
                    Fulfillment fulfillment = CarryoverEngine.calculateFulfillment(guaranteed, fulfilled);
                    return new MemberAttendance(member.getId(), member.getName(),
                            fulfillment.fulfilled(), fulfillment.guaranteed(), fulfillment.shortfall(), fulfillment.shortfall() > 0);
                })
                .toList();

        return new GroupAttendance(group.getId(), group.getDayOfWeek(), group.getTimeSlot(), year, month, guaranteed, memberAttendances);
    }

    // E-2: 전체조를 돌면서 미달자만 모은다.
    public List<ShortfallMember> getShortfallMembers(int year, int month) {
        List<ShortfallMember> result = new ArrayList<>();
        for (Group group : groupRepository.findAll()) {
            GroupAttendance attendance = getGroupAttendance(group.getId(), year, month);
            attendance.members().stream()
                    .filter(MemberAttendance::shortfallExists)
                    .forEach(m -> result.add(new ShortfallMember(
                            m.userId(), m.name(), group.getId(), group.getDayOfWeek(), group.getTimeSlot(),
                            m.fulfilled(), m.guaranteed(), m.shortfall())));
        }
        return result;
    }

    // E-3: 그 달 모든 조의 활동 중 OTHER_GROUP 응답을 모아 부원별로 묶는다.
    public List<OtherGroupSummary> getOtherGroupSummary(int year, int month) {
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd = monthStart.withDayOfMonth(monthStart.lengthOfMonth());

        List<Activity> activitiesInMonth = activityRepository.findByActivityDateBetween(monthStart, monthEnd);
        Map<Long, Activity> activityById = activitiesInMonth.stream()
                .collect(Collectors.toMap(Activity::getId, a -> a));
        List<Long> activityIds = activitiesInMonth.stream().map(Activity::getId).toList();

        List<Participation> otherGroupParticipations = activityIds.isEmpty()
                ? List.of()
                : participationRepository.findByActivityIdInAndType(activityIds, ParticipationType.OTHER_GROUP);
        if (otherGroupParticipations.isEmpty()) {
            return List.of();
        }

        Map<Long, Group> groupById = groupRepository.findAllById(
                        activitiesInMonth.stream().map(Activity::getGroupId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(Group::getId, g -> g));
        Map<Long, String> nameById = userRepository.findAllById(
                        otherGroupParticipations.stream().map(Participation::getUserId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(User::getId, User::getName));

        Map<Long, List<Participation>> byUser = otherGroupParticipations.stream()
                .collect(Collectors.groupingBy(Participation::getUserId));

        return byUser.entrySet().stream()
                .map(entry -> {
                    List<OtherGroupActivityView> activities = entry.getValue().stream()
                            .map(p -> {
                                Activity activity = activityById.get(p.getActivityId());
                                Group group = groupById.get(activity.getGroupId());
                                return new OtherGroupActivityView(activity.getId(), activity.getActivityDate(),
                                        group.getDayOfWeek(), group.getTimeSlot());
                            })
                            .toList();
                    return new OtherGroupSummary(entry.getKey(), nameById.get(entry.getKey()), activities.size(), activities);
                })
                .toList();
    }

    private int countGuaranteed(Long groupId, LocalDate monthStart, LocalDate monthEnd) {
        return (int) activityRepository.findByGroupIdAndActivityDateBetween(groupId, monthStart, monthEnd).stream()
                .filter(a -> !a.isCancelled() && a.getActivityType() == ActivityType.REGULAR)
                .count();
    }

    private int countFulfilled(Long userId, LocalDate monthStart, LocalDate monthEnd) {
        List<Participation> candidates = participationRepository.findByUserIdAndTypeIn(userId, FULFILLING_TYPES);
        if (candidates.isEmpty()) {
            return 0;
        }
        List<Long> activityIds = candidates.stream().map(Participation::getActivityId).toList();
        Set<Long> activityIdsInMonth = activityRepository.findAllById(activityIds).stream()
                .filter(a -> !a.getActivityDate().isBefore(monthStart) && !a.getActivityDate().isAfter(monthEnd))
                .map(Activity::getId)
                .collect(Collectors.toSet());
        return (int) candidates.stream().filter(p -> activityIdsInMonth.contains(p.getActivityId())).count();
    }
}
