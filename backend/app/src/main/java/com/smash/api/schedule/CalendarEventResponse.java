package com.smash.api.schedule;

import com.smash.domain.schedule.Schedule;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class CalendarEventResponse {
    private Long id;
    private String title;
    private LocalDate date;
    private String memo;
    private String createdBy;

    public static CalendarEventResponse of(Schedule schedule) {
        return CalendarEventResponse.builder()
                .id(schedule.getId())
                .title(schedule.getTitle())
                .date(schedule.getDate())
                .memo(schedule.getMemo())
                .createdBy(schedule.getCreatedBy().getName())
                .build();
    }
}
