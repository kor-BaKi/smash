package com.smash.service;

import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleRepository;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.activity.CreatedBy;
import com.smash.domain.activity.FreePeriodRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// 매일 자정 스케줄러가 호출하는 것과 동일한 경로를, 조회 시점(D-1 등)에도 호출해서
// "서버가 자정에 죽어 있었던 날"을 보정한다 (04-핵심로직.md "lazy 생성 보정 권장").
@Service
@RequiredArgsConstructor
public class ActivityGenerationService {

    private final ActivityScheduleRepository activityScheduleRepository;
    private final ActivityRepository activityRepository;
    private final GroupRepository groupRepository;
    private final FreePeriodRepository freePeriodRepository;

    @Transactional
    public void ensureActivitiesExistForDate(LocalDate date) {
        DayOfWeek dayOfWeek = toDomainDayOfWeek(date.getDayOfWeek());
        if (dayOfWeek == null) {
            return; // 주말은 운영 요일이 아니라 ActivitySchedule 자체가 없다.
        }

        List<ActivitySchedule> activeSchedules = activityScheduleRepository.findAll().stream()
                .filter(schedule -> schedule.isActive() && schedule.getDayOfWeek() == dayOfWeek)
                .toList();
        if (activeSchedules.isEmpty()) {
            return;
        }

        ActivityType activityType = isFreePeriod(date) ? ActivityType.FREE : ActivityType.REGULAR;

        for (ActivitySchedule schedule : activeSchedules) {
            groupRepository.findByDayOfWeekAndTimeSlot(schedule.getDayOfWeek(), schedule.getTimeSlot())
                    .ifPresent(group -> createIfMissing(group, date, activityType));
        }
    }

    private void createIfMissing(Group group, LocalDate date, ActivityType activityType) {
        if (!activityRepository.existsByGroupIdAndActivityDate(group.getId(), date)) {
            activityRepository.save(Activity.create(group.getId(), date, activityType, CreatedBy.AUTO));
        }
    }

    private boolean isFreePeriod(LocalDate date) {
        return !freePeriodRepository.findByStartDateLessThanEqualAndEndDateGreaterThanEqual(date, date).isEmpty();
    }

    private DayOfWeek toDomainDayOfWeek(java.time.DayOfWeek javaDayOfWeek) {
        return switch (javaDayOfWeek) {
            case MONDAY -> DayOfWeek.MON;
            case TUESDAY -> DayOfWeek.TUE;
            case WEDNESDAY -> DayOfWeek.WED;
            case THURSDAY -> DayOfWeek.THU;
            case FRIDAY -> DayOfWeek.FRI;
            default -> null;
        };
    }
}
