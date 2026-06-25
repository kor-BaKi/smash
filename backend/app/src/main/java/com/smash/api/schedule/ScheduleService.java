package com.smash.api.schedule;

import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleRepository;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ScheduleService {  // 정규활동 일정 관리 서비스

    private final ActivityScheduleRepository scheduleRepository;

    @Transactional
    public void updateSchedule(ScheduleRequest request) { // 임원이 설정한 활성/비활성 규칙 저장
        for (ScheduleRequest.ScheduleItem item : request.getSchedules()) {
            scheduleRepository.findByDayOfWeekAndTimeSlot(
                    item.getDayOfWeek(), item.getTimeSlot()
            ).ifPresentOrElse(
                    schedule -> schedule.updateActive(item.getIsActive()),
                    () -> scheduleRepository.save(
                            ActivitySchedule.builder()
                                    .dayOfWeek(item.getDayOfWeek())
                                    .timeSlot(item.getTimeSlot())
                                    .isActive(item.getIsActive())
                                    .build()
                    )
            );

        }
    }

    @Transactional
    public List<ScheduleResponse> getSchedules() { // 현재 설정된 규칙 조회
        return scheduleRepository.findAllOrderByDayOfWeek()
                .stream()
                .map(ScheduleResponse::of)
                .toList();
    }
}
