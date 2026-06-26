package com.smash.api.activity;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import com.smash.scheduler.ActivityScheduler;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ActivityService {

    private final ActivityRepository activityRepository;
    private final ParticipationRepository participationRepository;
    private final UserRepository userRepository;
    private final ActivityScheduler activityScheduler;

    // D-1. 오늘 내 활동 조회
    @Transactional
    public List<ActivityResponse> getTodayActivities(Long userId) {
        User user = getUser(userId);
        LocalDate today = LocalDate.now();

        // 오늘 전체 활동 조회 (lazy 생성 포함)
        List<Activity> todayActivities = activityRepository.findByActivityDate(today);

        List<ActivityResponse> responses = new ArrayList<>();
        for (Activity activity : todayActivities) {
            if (activity.isCancelled()) continue;

            boolean isMyGroup = user.getGroupId() != null && // 부원이 조에 배정됐는지
                    user.getGroupId().equals(activity.getGroup().getId()); // 부원의 조 iD와 활동의 조 id가 같은지

            List<String> buttons = resolvedButtons(user, activity, isMyGroup);
            boolean voteClosed = isVoteClosed(activity);

            Participation myParticipation = participationRepository
                    .findByActivityAndUser(activity, user).orElse(null);

            responses.add(ActivityResponse.builder()
                    .activityId(activity.getId())
                    .activityDate(activity.getActivityDate())
                    .groupId(activity.getGroup().getId())
                    .groupLabel(activity.getGroup().getLabel())
                    .activityType(activity.getActivityType())
                    .isMyGroup(isMyGroup).availableButtons(buttons)
                    .myParticipation(myParticipation == null ? null
                            : ActivityResponse.ParticipationInfo.builder()
                                    .participationId(myParticipation.getId())
                                    .type(myParticipation.getType().name())
                                    .targetActivityId(myParticipation.getCarryoverTarget() == null
                                                      ? null : myParticipation.getCarryoverTarget().getId())
                                    .build())
                            .voteClosed(voteClosed)
                    .build());
        }

        return responses;
    }

    // D-2. 참여 응답 (이월 포함 통합)
    @Transactional
    public void participate(Long userId, Long activityId, ParticipationRequest request) {
        User user = getUser(userId);
        Activity activity = getActivity(activityId);

        // 투표 마감 확인
        if (isVoteClosed(activity)) {
            throw new BusinessException("VOTE_CLOSED", "투표가 마감되었습니다.");
        }

        // CARRYOVER 추가 검증
        Activity carryoverTarget = null;
        if (request.getType() == ParticipationType.CARRYOVER) {
            if (request.getTargetActivityId() == null) {
                throw new BusinessException("INVALID_INPUT", "이월 대상 활동을 선택해주세요.");
            }
            carryoverTarget = getActivity(request.getTargetActivityId());

            // 후보 재검증
            boolean isValidTarget = getCarryoverCandidates(userId, activityId)
                    .stream()
                    .anyMatch(c -> c.getTargetActivityId().equals(request.getTargetActivityId()));

            if (!isValidTarget) {
                throw new BusinessException("INVALID_CARRYOVER_TARGET", "이월 대상으로 선택할 수 없는 날짜입니다.");
            }
        }

        // upsert: 있으면 수정, 없으면 생성
        Participation participation = participationRepository
                .findByActivityAndUser(activity, user).orElse(null);

        if (participation == null) {
            participationRepository.save(Participation.builder()
                    .activity(activity).user(user).type(request.getType()).carryoverTarget(carryoverTarget).build());
        } else {
            participation.updateType(request.getType(), carryoverTarget);
        }
    }

    // D-3. 이월 후보 조회
    @Transactional(readOnly = true)
    public List<CarryoverCandidateResponse> getCarryoverCandidates(Long userId, Long activityId) {
        User user = getUser(userId);
        Activity activity = getActivity(activityId);
        LocalDate today = activity.getActivityDate();

        // 당월 범위
        YearMonth month = YearMonth.from(today);
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();

        // 당월 본인 조 활동 조회
        List<Activity> myGroupActivities = activityRepository
                .findActivitiesByGroupAndMonth(user.getGroupId(), start, end);

        List<CarryoverCandidateResponse> candidates = new ArrayList<>();

        for (Activity act : myGroupActivities) {
            if (act.getId().equals(activityId)) continue;

            // 이미 자격 빠진 날 제외 (hasCarryoverOut)
            if (participationRepository.existsByUserAndCarryoverTarget(user, act)) continue;

            if (act.getActivityDate().isAfter(today)) {
                // 미래 -> FUTURE
                candidates.add(CarryoverCandidateResponse.builder()
                        .targetActivityId(act.getId()).date(act.getActivityDate()).status("FUTURE").build());
            } else if (act.getActivityDate().isBefore(today)) {
                // 과거 -> 정규 참여 안 했으면 PAST_ABSENT (hasRegularAttend)
                boolean attended = participationRepository.existsByUserAndActivityAndType(
                        user, act, ParticipationType.REGULAR
                );
                if (!attended) {
                    candidates.add(CarryoverCandidateResponse.builder()
                            .targetActivityId(act.getId()).date(act.getActivityDate()).status("PAST_ABSENT").build());
                }
            }
        }


        return candidates;
    }

    // D-4. 응답 취소
    @Transactional
    public void cancelParticipation(Long userId, Long activityId) {
        User user = getUser(userId);
        Activity activity = getActivity(activityId);

        if (isVoteClosed(activity)) {
            throw new BusinessException("VOTE_CLOSED", "투표가 마감되어 취소할 수 없습니다.");
        }

        Participation participation = participationRepository
                .findByActivityAndUser(activity, user)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "응답 기록이 없습니다."
                ));

        participationRepository.delete(participation);
    }

    // D-5. 활동 상세 조회
    @Transactional(readOnly = true)
    public ActivityDetailResponse getActivityDetail(Long userId, Long activityId) {
        Activity activity = getActivity(activityId);

        List<Participation> participations = participationRepository.findByActivity(activity);

        // 유형별로 분류
        List<ActivityDetailResponse.UserInfo> regular = new ArrayList<>();
        List<ActivityDetailResponse.UserInfo> carryover = new ArrayList<>();
        List<ActivityDetailResponse.UserInfo> otherGroup = new ArrayList<>();
        List<ActivityDetailResponse.UserInfo> freeAttend = new ArrayList<>();
        List<ActivityDetailResponse.UserInfo> absent = new ArrayList<>();

        for (Participation p : participations) {
            ActivityDetailResponse.UserInfo info = ActivityDetailResponse.UserInfo.builder()
                    .userId(p.getUser().getId()).name(p.getUser().getName()).build();

            switch (p.getType()) {
                case REGULAR ->  regular.add(info);
                case CARRYOVER -> carryover.add(info);
                case OTHER_GROUP -> otherGroup.add(info);
                case FREE_ATTEND -> freeAttend.add(info);
                case ABSENT -> absent.add(info);
            }
        }
        return ActivityDetailResponse.builder()
                .activityId(activity.getId())
                .activityDate(activity.getActivityDate())
                .groupLabel(activity.getGroup().getLabel())
                .activityType(activity.getActivityType().name())
                .isCancelled(activity.isCancelled())
                .summary(ActivityDetailResponse.Summary.builder()
                        .regular(regular.size())
                        .carryover(carryover.size())
                        .otherGroup(otherGroup.size())
                        .freeAttend(freeAttend.size())
                        .absent(absent.size())
                        .build())
                .participants(ActivityDetailResponse.Participants.builder()
                        .regular(regular)
                        .carryover(carryover)
                        .otherGroup(otherGroup)
                        .freeAttend(freeAttend)
                        .absent(absent)
                        .build())
                .build();
    }

    // D-6. 날짜별 활동 목록 (임원)
    @Transactional(readOnly = true)
    public List<ActivitySummaryResponse> getActivitiesByDate(String dateStr) {
        LocalDate date = (dateStr == null) ? LocalDate.now() : LocalDate.parse(dateStr);
        List<Activity> activities = activityRepository.findByActivityDate(date);

        return activities.stream()
                .map(activity -> {
                    List<Participation> participations =
                            participationRepository.findByActivity(activity);
                    return ActivitySummaryResponse.builder()
                            .activityId(activity.getId())
                            .activityDate(activity.getActivityDate())
                            .groupLabel(activity.getGroup().getLabel())
                            .activityType(activity.getActivityType().name())
                            .isCancelled(activity.isCancelled())
                            .summary(ActivityDetailResponse.Summary.builder()
                                    .regular((int) participations.stream()
                                            .filter(p -> p.getType() == ParticipationType.REGULAR).count())
                                    .carryover((int) participations.stream()
                                            .filter(p -> p.getType() == ParticipationType.CARRYOVER).count())
                                    .otherGroup((int) participations.stream()
                                            .filter(p -> p.getType() == ParticipationType.OTHER_GROUP).count())
                                    .freeAttend((int) participations.stream()
                                            .filter(p -> p.getType() == ParticipationType.FREE_ATTEND).count())
                                    .absent((int) participations.stream()
                                            .filter(p -> p.getType() == ParticipationType.ABSENT).count())
                                    .build())
                            .build();
                })
                .toList();
    }

    // D-7. 활동 수동 제어 (임원)
    @Transactional
    public void updateActivity(Long activityId, ActivityUpdateRequest request) {
        Activity activity = getActivity(activityId);

        if (request.getIsCancelled() != null) {
            activity.cancel(request.getIsCancelled());
        }
        if (request.getActivityType() != null) {
            activity.changeType(request.getActivityType());
        }
    }


    // 버튼 분기 판정
    private List<String> resolvedButtons(User user, Activity activity, boolean isMyGroup) {
        if (activity.getActivityType() == ActivityType.FREE) { // 자유 활동
            return List.of("FREE_ATTEND", "ABSENT"); // 버튼은 참여, 불참 밖에 없음
        }

        if (isMyGroup) {  // 본인 조 정규 활동일 때
            // 자격이 빠진 날인지 확인 (hasCarryoverOut)
            boolean carryoverOut = participationRepository
                    .existsByUserAndCarryoverTarget(user, activity);
            if (carryoverOut) { // 이월 여부 판단
                return  List.of("CARRYOVER", "OTHER_GROUP"); // 이월할건지 타조참으로 할건지
            }
            return List.of("ATTEND", "ABSENT"); // 정규 참여
        }

        return List.of("CARRYOVER", "OTHER_GROUP"); // 본인 조 정규 활동이 아닌 경우 -> 이월 or 타조참
    }

    // 투표 마감 판정
    private boolean isVoteClosed(Activity activity) {
        LocalTime closeTime = activity.getGroup().getTimeSlot() == TimeSlot.SLOT_13_15
                ? LocalTime.of(13, 0)  // 1-3시 조면 13시 마감
                : LocalTime.of(15, 0); // 1-3 조가 아니면 15시 마감
        return LocalDate.now().isAfter(activity.getActivityDate()) ||
                (LocalDate.now().equals(activity.getActivityDate()) &&
                        LocalTime.now().isAfter(closeTime));
    }




    // 공통 헬퍼
    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
                ));
    }

    private Activity getActivity(Long activityId) {
        return activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "활동을 찾을 수 없습니다."
                ));
    }
}
