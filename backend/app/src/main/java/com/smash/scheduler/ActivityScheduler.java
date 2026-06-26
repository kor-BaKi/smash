package com.smash.scheduler;

import com.smash.domain.activity.*;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Slf4j // Lombok이 log 변수를 자동 생성
@Component
@RequiredArgsConstructor
public class ActivityScheduler {

    private final ActivityScheduleRepository scheduleRepository;
    private final ActivityRepository activityRepository;
    private final GroupRepository groupRepository;

    // 매일 자정에 실행 : [초] : (0 = 0초) [분] : (0 = 0분) [시] (0 = 0시) [일] : (* = 매일) [월] : * = 매월) [요일] : (* = 매일)
    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void createDetailActivities() {
        LocalDate today = LocalDate.now();
        log.info("활동 자동 생성 시작: {}", today);

        // 오늘 요일에 해당하는 활성 일정 조회
        List<ActivitySchedule> schedules = scheduleRepository.findAllOrderByDayOfWeek()
                .stream()
                .filter(s -> s.isActive() && s.getDayOfWeek().name().equals(
                        today.getDayOfWeek().name().substring(0, 3)))
                .toList();

        for (ActivitySchedule schedule : schedules) {
            // 해당 요일+시간대의 조 조회
            groupRepository.findByDayOfWeekAndTimeSlot(
                            schedule.getDayOfWeek(), schedule.getTimeSlot())
                    .ifPresent(group -> createActivityIfNotExists(group, today));
        }

        log.info("활동 자동 생성 완료: {}", today);
    }

    public void createActivityIfNotExists(Group group, LocalDate date) { // 활동이 없으면 생성 X
        // 이미 있으면 생성하지 않은 (중복 방지)
        if (activityRepository.findByGroupAndActivityDate(group, date).isPresent()) {
            return;
        }

        Activity activity = Activity.builder()
                .group(group)
                .activityDate(date)
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build();

        activityRepository.save(activity);
        log.info("활동 생성: {} {} {}", group.getLabel(), date, ActivityType.REGULAR);
    }

}
