package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import com.smash.domain.user.Role;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ParticipationService {

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final ActivityRepository activityRepository;
    private final ParticipationRepository participationRepository;
    private final ActivityGenerationService activityGenerationService;

    // D-1: scope=MY는 본인조 활동만, ALL은 오늘 생성된 전체조 활동.
    @Transactional
    public List<ActivityTodayView> getTodayActivities(Long userId, Scope scope) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        LocalDate today = LocalDate.now();
        activityGenerationService.ensureActivitiesExistForDate(today);

        List<Activity> activities = (scope == Scope.MY)
                ? myGroupActivityToday(user, today)
                : activityRepository.findByActivityDate(today);
        if (activities.isEmpty()) {
            return List.of();
        }

        List<Long> activityIds = activities.stream().map(Activity::getId).toList();
        List<ParticipationRecord> participationRecords = loadParticipationRecords(userId, activityIds);
        Map<Long, Participation> myResponseByActivity = participationRepository.findByUserIdAndActivityIdIn(userId, activityIds)
                .stream()
                .collect(Collectors.toMap(Participation::getActivityId, p -> p));
        Map<Long, Group> groupById = groupRepository.findAllById(
                        activities.stream().map(Activity::getGroupId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(Group::getId, g -> g));

        return activities.stream()
                .map(activity -> toTodayView(activity, user, groupById.get(activity.getGroupId()), participationRecords, myResponseByActivity))
                .toList();
    }

    private List<Activity> myGroupActivityToday(User user, LocalDate today) {
        if (user.getGroupId() == null) {
            return List.of();
        }
        return activityRepository.findByGroupIdAndActivityDate(user.getGroupId(), today)
                .map(List::of)
                .orElse(List.of());
    }

    private ActivityTodayView toTodayView(
            Activity activity, User user, Group group,
            List<ParticipationRecord> participationRecords, Map<Long, Participation> myResponseByActivity) {
        boolean isMyGroup = activity.getGroupId().equals(user.getGroupId());
        List<ParticipationType> buttons = CarryoverEngine.resolveButtons(toActivityInfo(activity), isMyGroup, participationRecords);
        Participation myResponse = myResponseByActivity.get(activity.getId());

        return new ActivityTodayView(
                activity.getId(),
                activity.getActivityDate(),
                group.getId(),
                group.getDayOfWeek(),
                group.getTimeSlot(),
                activity.getActivityType(),
                isMyGroup,
                buttons,
                myResponse == null ? null : myResponse.getType(),
                myResponse == null ? null : myResponse.getCarryoverTargetActivityId(),
                isVoteClosed(activity, group)
        );
    }

    // D-2: 이월 포함 모든 응답을 한 엔드포인트에서 처리. (activity_id,user_id) UNIQUE upsert.
    @Transactional
    public ParticipationResult submitParticipation(Long userId, Long activityId, ParticipationType type, Long targetActivityId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Group group = groupRepository.findById(activity.getGroupId())
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        checkVoteClosed(activity, group, user.getRole());

        boolean isMyGroup = activity.getGroupId().equals(user.getGroupId());
        List<ParticipationRecord> myParticipations = loadParticipationRecords(userId, List.of(activityId));
        List<ParticipationType> availableButtons = CarryoverEngine.resolveButtons(toActivityInfo(activity), isMyGroup, myParticipations);
        if (!availableButtons.contains(type)) {
            throw new BusinessException(ErrorCode.INVALID_PARTICIPATION_TYPE);
        }

        Long resolvedTarget = (type == ParticipationType.CARRYOVER)
                ? resolveCarryoverTarget(user, activity, targetActivityId)
                : null;

        Participation participation = participationRepository.findByActivityIdAndUserId(activityId, userId)
                .map(existing -> {
                    existing.update(type, resolvedTarget);
                    return existing;
                })
                .orElseGet(() -> participationRepository.save(Participation.create(activityId, userId, type, resolvedTarget)));

        return new ParticipationResult(participation.getId(), participation.getType(), participation.getCarryoverTargetActivityId());
    }

    private Long resolveCarryoverTarget(User user, Activity currentActivity, Long targetActivityId) {
        List<CarryoverCandidate> candidates = getCarryoverCandidatesInternal(user, currentActivity);
        if (candidates.isEmpty()) {
            throw new BusinessException(ErrorCode.CARRYOVER_NOT_AVAILABLE);
        }
        if (targetActivityId == null || candidates.stream().noneMatch(c -> c.activityId().equals(targetActivityId))) {
            throw new BusinessException(ErrorCode.INVALID_CARRYOVER_TARGET);
        }
        return targetActivityId;
    }

    // D-3
    @Transactional(readOnly = true)
    public List<CarryoverCandidate> getCarryoverCandidates(Long userId, Long activityId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        return getCarryoverCandidatesInternal(user, activity);
    }

    private List<CarryoverCandidate> getCarryoverCandidatesInternal(User user, Activity currentActivity) {
        if (user.getGroupId() == null) {
            return List.of();
        }
        LocalDate date = currentActivity.getActivityDate();
        LocalDate monthStart = date.withDayOfMonth(1);
        LocalDate monthEnd = date.withDayOfMonth(date.lengthOfMonth());

        List<Activity> myGroupActivities = activityRepository
                .findByGroupIdAndActivityDateBetween(user.getGroupId(), monthStart, monthEnd)
                .stream()
                .filter(a -> !a.isCancelled())
                .toList();
        List<Long> activityIds = myGroupActivities.stream().map(Activity::getId).toList();
        List<ParticipationRecord> myParticipations = loadParticipationRecords(user.getId(), activityIds);
        List<ActivityInfo> activityInfos = myGroupActivities.stream().map(this::toActivityInfo).toList();

        return CarryoverEngine.getCarryoverCandidates(activityInfos, myParticipations, LocalDate.now());
    }

    // D-4: 기록 삭제만으로 이월 대상이었던 날의 자격이 복구된다 (별도 로직 불필요).
    @Transactional
    public void deleteParticipation(Long userId, Long activityId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Group group = groupRepository.findById(activity.getGroupId())
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        checkVoteClosed(activity, group, user.getRole());
        participationRepository.deleteByActivityIdAndUserId(activityId, userId);
    }

    private List<ParticipationRecord> loadParticipationRecords(Long userId, List<Long> activityIds) {
        List<Participation> byActivity = participationRepository.findByUserIdAndActivityIdIn(userId, activityIds);
        List<Participation> byCarryoverTarget = participationRepository.findByUserIdAndCarryoverTargetActivityIdIn(userId, activityIds);
        return Stream.concat(byActivity.stream(), byCarryoverTarget.stream())
                .map(p -> new ParticipationRecord(p.getActivityId(), p.getType(), p.getCarryoverTargetActivityId()))
                .toList();
    }

    private ActivityInfo toActivityInfo(Activity activity) {
        return new ActivityInfo(activity.getId(), activity.getActivityDate(), activity.getGroupId(),
                activity.getActivityType(), activity.isCancelled());
    }

    // 임원은 시점 제한 없이 수정 가능 (CLAUDE.md 3.5)
    private void checkVoteClosed(Activity activity, Group group, Role role) {
        if (role == Role.ADMIN) {
            return;
        }
        LocalDateTime deadline = LocalDateTime.of(activity.getActivityDate(), group.getTimeSlot().startTime());
        if (!LocalDateTime.now().isBefore(deadline)) {
            throw new BusinessException(ErrorCode.VOTE_CLOSED);
        }
    }

    private boolean isVoteClosed(Activity activity, Group group) {
        LocalDateTime deadline = LocalDateTime.of(activity.getActivityDate(), group.getTimeSlot().startTime());
        return !LocalDateTime.now().isBefore(deadline);
    }
}
