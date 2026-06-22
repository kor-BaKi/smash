package com.smash.service;

import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleRepository;
import com.smash.domain.activity.ActivityScheduleSlot;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ActivityScheduleService {

    private final ActivityScheduleRepository activityScheduleRepository;

    // B-4: 전체교체. 기존 행을 모두 지우고 요청받은 슬롯으로 다시 채운다.
    @Transactional
    public List<ActivitySchedule> replaceAll(List<ActivityScheduleSlot> slots) {
        activityScheduleRepository.deleteAllInBatch();
        List<ActivitySchedule> schedules = slots.stream()
                .map(slot -> ActivitySchedule.create(slot.dayOfWeek(), slot.timeSlot(), slot.active()))
                .toList();
        return activityScheduleRepository.saveAll(schedules);
    }

    @Transactional(readOnly = true)
    public List<ActivitySchedule> getAll() {
        return activityScheduleRepository.findAll();
    }
}
