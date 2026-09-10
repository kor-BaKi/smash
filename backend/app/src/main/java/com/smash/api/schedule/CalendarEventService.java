package com.smash.api.schedule;

import com.smash.common.exception.BusinessException;
import com.smash.domain.schedule.Schedule;
import com.smash.domain.schedule.ScheduleRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CalendarEventService {

    private final ScheduleRepository scheduleRepository;
    private final UserRepository userRepository;

    // 월별 일정 조회
    @Transactional(readOnly = true)
    public List<CalendarEventResponse> getEvents(int year, int month) {
        return scheduleRepository.findByDateYearAndDateMonth(year, month)
                .stream()
                .map(CalendarEventResponse::of)
                .toList();
    }

    // 일정 생성 (ADMIN)
    @Transactional
    public CalendarEventResponse create(CalendarEventRequest request, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."
                ));

        Schedule schedule = scheduleRepository.save(
                Schedule.builder()
                        .title(request.getTitle())
                        .date(request.getDate())
                        .memo(request.getMemo())
                        .createdBy(user)
                        .build()
        );

        return CalendarEventResponse.of(schedule);
    }

    // 일정 삭제 (임원만)
    @Transactional
    public void delete(Long scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 일정입니다."
                ));

        scheduleRepository.delete(schedule);
    }

}
