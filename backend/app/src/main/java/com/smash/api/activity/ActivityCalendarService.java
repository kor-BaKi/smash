package com.smash.api.activity;

import com.smash.api.schedule.FreePeriodResponse;
import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleRepository;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.activity.FreePeriod;
import com.smash.domain.activity.FreePeriodRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ActivityCalendarService {

    private static final int MIN_YEAR = 2000;
    private static final int MAX_YEAR = 2100;

    private final UserRepository userRepository;
    private final GroupRepository groupRepository;
    private final ActivityRepository activityRepository;
    private final ActivityScheduleRepository activityScheduleRepository;
    private final FreePeriodRepository freePeriodRepository;

    @Transactional(readOnly = true)
    public ActivityCalendarResponse getCalendar(Long userId, Integer year, Integer month) {
        return getCalendar(userId, year, month, LocalDate.now());
    }

    // 기준일(today)을 받는 버전: 테스트에서 "오늘"을 고정하기 위해 분리
    ActivityCalendarResponse getCalendar(Long userId, Integer year, Integer month, LocalDate today) {
        if (year == null || month == null
                || year < MIN_YEAR || year > MAX_YEAR || month < 1 || month > 12) {
            throw new BusinessException("INVALID_INPUT", "연도와 월을 올바르게 입력해 주세요.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."));

        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();

        // 해당 월과 겹치는 자유 활동 기간 (조와 무관해서 미배정 부원에게도 내려준다)
        List<FreePeriod> periods = freePeriodRepository.findOverlapping(start, end);
        List<FreePeriodResponse> freePeriods = periods.stream()
                .map(FreePeriodResponse::of)
                .toList();

        Group group = user.getGroupId() == null
                ? null
                : groupRepository.findById(user.getGroupId()).orElse(null);

        if (group == null) {
            return ActivityCalendarResponse.builder()
                    .year(year)
                    .month(month)
                    .myGroup(null)
                    .activities(List.of())
                    .freePeriods(freePeriods)
                    .build();
        }

        // 실제 활동 행 (취소 포함). (group, date)가 유니크라 날짜당 최대 1건
        Map<LocalDate, Activity> actualByDate = activityRepository
                .findAllActivitiesByGroupAndMonth(group.getId(), start, end)
                .stream()
                .collect(Collectors.toMap(Activity::getActivityDate, Function.identity()));

        boolean scheduleActive = activityScheduleRepository
                .findByDayOfWeekAndTimeSlot(group.getDayOfWeek(), group.getTimeSlot())
                .map(ActivitySchedule::isActive)
                .orElse(false);

        // 날짜를 하루씩 순회하므로 날짜당 한 건만 나오고, 월 경계에서도 중복되지 않는다
        List<ActivityCalendarResponse.Day> days = new ArrayList<>();
        for (LocalDate date = start; !date.isAfter(end); date = date.plusDays(1)) {
            Activity actual = actualByDate.get(date);
            if (actual != null) {
                days.add(ActivityCalendarResponse.Day.builder()
                        .date(date)
                        .activityId(actual.getId())
                        .activityType(actual.getActivityType().name())
                        .isCancelled(actual.isCancelled())
                        .isProjected(false)
                        .build());
            } else if (date.isAfter(today) && scheduleActive && matchesWeekday(group, date)) {
                // 활동은 당일에만 생성되므로, 미래는 스케줄러의 생성 규칙대로 계산한다
                days.add(ActivityCalendarResponse.Day.builder()
                        .date(date)
                        .activityId(null)
                        .activityType(resolveType(periods, date).name())
                        .isCancelled(false)
                        .isProjected(true)
                        .build());
            }
        }

        return ActivityCalendarResponse.builder()
                .year(year)
                .month(month)
                .myGroup(ActivityCalendarResponse.MyGroup.builder()
                        .groupId(group.getId())
                        .label(group.getLabel())
                        .build())
                .activities(days)
                .freePeriods(freePeriods)
                .build();
    }

    // ActivityScheduler.createDetailActivities 와 같은 요일 비교 (MON ~ FRI)
    private boolean matchesWeekday(Group group, LocalDate date) {
        return group.getDayOfWeek().name()
                .equals(date.getDayOfWeek().name().substring(0, 3));
    }

    // ActivityScheduler.resolveActivityType 과 같은 규칙: 자유 활동 기간이면 FREE
    private ActivityType resolveType(List<FreePeriod> periods, LocalDate date) {
        return periods.stream().anyMatch(period -> period.contains(date))
                ? ActivityType.FREE
                : ActivityType.REGULAR;
    }
}
