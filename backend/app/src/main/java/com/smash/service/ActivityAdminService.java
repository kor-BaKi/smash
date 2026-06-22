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
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ActivityAdminService {

    private final ActivityRepository activityRepository;
    private final GroupRepository groupRepository;
    private final ParticipationRepository participationRepository;
    private final UserRepository userRepository;
    private final ActivityGenerationService activityGenerationService;

    // D-5: 공통(임원/부원) 조회. 집계·명단만 - 충족/미달 등 평가성 데이터는 포함하지 않는다(E 전용).
    @Transactional(readOnly = true)
    public ActivityDetail getActivityDetail(Long activityId) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        Group group = groupRepository.findById(activity.getGroupId())
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        List<Participation> participations = participationRepository.findByActivityId(activityId);

        Map<Long, String> nameById = nameById(participations);
        ParticipationSummary summary = summarize(participations);
        ActivityParticipants participants = groupParticipants(participations, nameById);

        return new ActivityDetail(
                activity.getId(), activity.getActivityDate(), group.getId(), group.getDayOfWeek(), group.getTimeSlot(),
                activity.getActivityType(), activity.isCancelled(), summary, participants);
    }

    // D-6: 날짜 미지정 시 오늘. 조회 전 lazy 생성 보정도 함께 수행.
    @Transactional
    public List<ActivitySummaryView> getActivitiesByDate(LocalDate date) {
        activityGenerationService.ensureActivitiesExistForDate(date);
        List<Activity> activities = activityRepository.findByActivityDate(date);
        Map<Long, Group> groupById = groupRepository.findAllById(
                        activities.stream().map(Activity::getGroupId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(Group::getId, g -> g));

        return activities.stream()
                .map(activity -> {
                    Group group = groupById.get(activity.getGroupId());
                    ParticipationSummary summary = summarize(participationRepository.findByActivityId(activity.getId()));
                    return new ActivitySummaryView(
                            activity.getId(), group.getId(), group.getDayOfWeek(), group.getTimeSlot(),
                            activity.getActivityType(), activity.isCancelled(), summary);
                })
                .toList();
    }

    // D-7: isCancelled/activityType 중 최소 하나. 과거 응답(Participation)은 삭제하지 않는다.
    @Transactional
    public void updateActivity(Long activityId, Boolean isCancelled, ActivityType activityType) {
        if (isCancelled == null && activityType == null) {
            throw new BusinessException(ErrorCode.INVALID_REQUEST);
        }
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));

        if (isCancelled != null) {
            activity.updateCancelled(isCancelled);
        }
        if (activityType != null) {
            activity.updateActivityType(activityType);
        }
    }

    private Map<Long, String> nameById(List<Participation> participations) {
        List<Long> userIds = participations.stream().map(Participation::getUserId).distinct().toList();
        return userRepository.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, User::getName));
    }

    private ParticipationSummary summarize(List<Participation> participations) {
        int regular = 0;
        int carryover = 0;
        int otherGroup = 0;
        int freeAttend = 0;
        int absent = 0;
        for (Participation p : participations) {
            switch (p.getType()) {
                case REGULAR -> regular++;
                case CARRYOVER -> carryover++;
                case OTHER_GROUP -> otherGroup++;
                case FREE_ATTEND -> freeAttend++;
                case ABSENT -> absent++;
            }
        }
        return new ParticipationSummary(regular, carryover, otherGroup, freeAttend, absent);
    }

    private ActivityParticipants groupParticipants(List<Participation> participations, Map<Long, String> nameById) {
        return new ActivityParticipants(
                toViews(participations, ParticipationType.REGULAR, nameById),
                toViews(participations, ParticipationType.CARRYOVER, nameById),
                toViews(participations, ParticipationType.OTHER_GROUP, nameById),
                toViews(participations, ParticipationType.FREE_ATTEND, nameById),
                toViews(participations, ParticipationType.ABSENT, nameById)
        );
    }

    private List<ParticipantView> toViews(List<Participation> participations, ParticipationType type, Map<Long, String> nameById) {
        return participations.stream()
                .filter(p -> p.getType() == type)
                .map(p -> new ParticipantView(p.getUserId(), nameById.get(p.getUserId())))
                .toList();
    }
}
