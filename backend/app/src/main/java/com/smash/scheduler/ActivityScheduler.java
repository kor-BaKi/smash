package com.smash.scheduler;

import com.smash.service.ActivityGenerationService;
import java.time.LocalDate;
import java.time.ZoneId;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ActivityScheduler {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    private final ActivityGenerationService activityGenerationService;

    @Scheduled(cron = "0 0 0 * * *", zone = "Asia/Seoul")
    public void generateTodayActivities() {
        activityGenerationService.ensureActivitiesExistForDate(LocalDate.now(KST));
    }
}
